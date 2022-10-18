#!/usr/bin/env gjs
/* rotator.js
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
 * https://raw.githubusercontent.com/kosmospredanie/gnome-shell-extension-screen-autorotate/main/screen-autorotate%40kosmospredanie.yandex.ru/rotator.js
 */

'use strict';

const { Gio } = imports.gi;

imports.searchPath.unshift('.');
const BusUtils = imports.busUtils;

function call_dbus_method(method, params = null) {
    let connection = Gio.bus_get_sync(Gio.BusType.SESSION, null);
    return connection.call_sync(
        'org.gnome.Mutter.DisplayConfig',
        '/org/gnome/Mutter/DisplayConfig',
        'org.gnome.Mutter.DisplayConfig',
        method,
        params,
        null,
        Gio.DBusCallFlags.NONE,
        -1,
        null);
}

function get_state() {
    let result = call_dbus_method('GetCurrentState');
    return new BusUtils.DisplayConfigState(result);
}

function rotate_to(transform) {
    let state = this.get_state();
    let builtin_monitor = state.builtin_monitor;
    let logical_monitor = state.get_logical_monitor_for(builtin_monitor.connector);
    logical_monitor.transform = transform;
    // let variant = state.pack_to_apply( BusUtils.Methods['temporary'] );
    let variant = state.pack_to_apply( BusUtils.Methods['persistent'] );
    call_dbus_method('ApplyMonitorsConfig', variant);
	log("rotation done");
}

let state = this.get_state();
let builtin_monitor = state.builtin_monitor;
let logical_monitor = state.get_logical_monitor_for(builtin_monitor.connector);
log("current monitor state:");
    // 'normal': 0,
    // 'left-up': 1,
    // 'bottom-up': 2,
    // 'right-up': 3
log(logical_monitor.transform);
let target_orientation;
switch (logical_monitor.transform) {
	case 0:
	case 2:
		target_orientation = 1;
		break;
	case 1:
	case 3:
		target_orientation = 0;
		break;
}
log("target");
log(target_orientation);
// log(logical_monitor.transform);

// let target = parseInt(ARGV[0]);
rotate_to(target_orientation);
