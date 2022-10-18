/* busUtils.js
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * Based on:
 * https://github.com/kosmospredanie/gnome-shell-extension-screen-autorotate/blob/main/screen-autorotate%40kosmospredanie.yandex.ru/busUtils.js
 */

'use strict';

const { GLib, Gio } = imports.gi;

var Methods = Object.freeze({
    'verify': 0,
    'temporary': 1,
    'persistent': 2
});

var Monitor = class Monitor {
    constructor(variant) {
        let unpacked = variant.unpack();
        this.connector = unpacked[0].unpack()[0].unpack();

        let modes = unpacked[1].unpack();
        for (let i = 0; i < modes.length; i++) {
            let mode = modes[i].unpack();
            let id = mode[0].unpack();
            let mode_props = mode[6].unpack();
			if ("is-current" in mode_props){
				let is_current = mode_props['is-current'].unpack().get_boolean();
				if (is_current) {
					log("found current");
					this.current_mode_id = id;
					break;
				}
        	}
		}

        let props = unpacked[2].unpack();
        if ('is-underscanning' in props) {
            this.is_underscanning = props['is-underscanning'].unpack().get_boolean();
        } else {
            this.is_underscanning = false;
        }
        if ('is-builtin' in props) {
            this.is_builtin = props['is-builtin'].unpack().get_boolean();
        } else {
            this.is_builtin = false;
        }
    }
}

var LogicalMonitor = class LogicalMonitor {
    constructor(variant) {
        let unpacked = variant.unpack();
        this.x = unpacked[0].unpack();
        this.y = unpacked[1].unpack();
        this.scale = unpacked[2].unpack();
        this.transform = unpacked[3].unpack();
        this.primary = unpacked[4].unpack();
        // [ [connector, vendor, product, serial]* ]
        this.monitors = unpacked[5].deep_unpack();
        this.properties = unpacked[6].unpack();
        for (let key in this.properties) {
            this.properties[key] = this.properties[key].unpack().unpack();
        }
    }
}

var DisplayConfigState = class DisplayConfigState {
    constructor(result) {
        let unpacked = result.unpack();

        this.serial = unpacked[0].unpack();

        this.monitors = [];
        let monitors = unpacked[1].unpack();
        monitors.forEach(monitor_packed => {
			// log("optionals");
			// log(monitor_packed.unpack()[1].unpack()[0].unpack()[6].unpack());
			// let optionals = monitor_packed.unpack()[1].unpack()[3].unpack()[6].unpack();
			// log("is-current" in optionals)
			// for (var k in optionals){
			// 	log(k);
			// 	log(optionals[k]);
			// }
            let monitor = new Monitor(monitor_packed);
            this.monitors.push(monitor);
        });

        this.logical_monitors = [];
        let logical_monitors = unpacked[2].unpack();
        logical_monitors.forEach(lmonitor_packed => {
            let lmonitor = new LogicalMonitor(lmonitor_packed);
            this.logical_monitors.push(lmonitor);
        });

        this.properties = unpacked[3].unpack();
        for (let key in this.properties) {
            this.properties[key] = this.properties[key].unpack().unpack();
        }
    }

    get builtin_monitor() {
        for (let i = 0; i < this.monitors.length; i++) {
            let monitor = this.monitors[i];
            if (monitor.is_builtin) {
                return monitor;
            }
        }
        return null;
    }

    get_monitor(connector) {
        for (let i = 0; i < this.monitors.length; i++) {
            let monitor = this.monitors[i];
            if (monitor.connector === connector) {
                return monitor;
            }
        }
        return null;
    }

    get_logical_monitor_for(connector) {
        for (let i = 0; i < this.logical_monitors.length; i++) {
            let lmonitor = this.logical_monitors[i];
            for (let j = 0; j < lmonitor.monitors.length; j++) {
                let lm_connector = lmonitor.monitors[j][0];
                if (connector === lm_connector) {
                    return lmonitor;
                }
            }
        }
        return null;
    }

    pack_to_apply(method) {
        let packing = [ this.serial, method, [], {} ];
        let logical_monitors = packing[2];
        let properties = packing[3];

        this.logical_monitors.forEach(lmonitor => {
            let lmonitor_pack = [
                lmonitor.x,
                lmonitor.y,
                lmonitor.scale,
                lmonitor.transform,
                lmonitor.primary,
                []
            ];
            let monitors = lmonitor_pack[5];
            for (let i = 0; i < lmonitor.monitors.length; i++) {
                let connector = lmonitor.monitors[i][0];
                let monitor = this.get_monitor(connector);
                monitors.push([
                    connector,
                    monitor.current_mode_id,
                    {
                        'enable_underscanning': new GLib.Variant('b', monitor.is_underscanning)
                    }
                ]);
            }
            logical_monitors.push(lmonitor_pack);
        });

        if ('layout-mode' in this.properties) {
            properties['layout-mode'] = new GLib.Variant('b', this.properties['layout-mode']);
        }

        return new GLib.Variant('(uua(iiduba(ssa{sv}))a{sv})', packing);
    }
}
