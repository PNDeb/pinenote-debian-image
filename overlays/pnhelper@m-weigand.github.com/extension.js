/*
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
 * https://raw.githubusercontent.com/kosmospredanie/gnome-shell-extension-screen-autorotate/main/screen-autorotate%40kosmospredanie.yandex.ru/extension.js
 */
'use strict';
const St = imports.gi.St;
const { Clutter, GLib, Gio, GObject } = imports.gi;
const QuickSettings = imports.ui.quickSettings;

// This is the live instance of the Quick Settings menu
const QuickSettingsMenu = imports.ui.main.panel.statusArea.quickSettings;

const ExtensionUtils = imports.misc.extensionUtils;
const Me = ExtensionUtils.getCurrentExtension();
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;
const Slider = imports.ui.slider;

const Orientation = Object.freeze({
    'normal': 0,
    'left-up': 1,
    'bottom-up': 2,
    'right-up': 3
});

const BusUtils = Me.imports.busUtils;

const ebc = Me.imports.ebc;


var TriggerRefreshButton = GObject.registerClass(
	class TriggerRefreshButton extends PanelMenu.Button {
    _init() {
        super._init();
        this.set_track_hover(true);
        this.set_reactive(true);

        this.add_child(new St.Icon({
			icon_name: 'view-refresh-symbolic',
			style_class: 'system-status-icon'
		}));
        this.connect('button-press-event', this._trigger_btn.bind(this));
        this.connect('touch-event', this._trigger_touch.bind(this));
    }

    _trigger_touch(widget, event) {
		if (event.type() !== Clutter.EventType.TOUCH_BEGIN){
			ebc.ebc_trigger_global_refresh();
		}
    }

    _trigger_btn(widget, event) {
		ebc.ebc_trigger_global_refresh();
    }
});


class Extension {
    constructor() {
        this._indicator = null;
        this._indicator2 = null;

		// the button widgets
		this.bw_but_grayscale = new PopupMenu.PopupMenuItem(_('Grayscale Mode (v2)'));
		this.bw_but_bw_dither = new PopupMenu.PopupMenuItem(_('BW+Dither Mode'));
		this.bw_but_bw = new PopupMenu.PopupMenuItem(_('BW Mode'));
        this.m_bw_slider = new PopupMenu.PopupBaseMenuItem({ activate: true });
		this.mitem_bw_dither_invert = new PopupMenu.PopupMenuItem(_('BW Invert On'));


		this.panel_label = new St.Label({
			text: "DADA",
            y_expand: true,
            y_align: Clutter.ActorAlign.CENTER
        });

		const home = GLib.getenv("HOME");
		const file = Gio.file_new_for_path(home + "/.config/pinenote/do_not_show_overview");
		log("checking file");
		log(file);
		if (file.query_exists(null)){
			log("disabling overview");
			Main.sessionMode.hasOverview = false;
		}
    }

	onWaveformChanged(connection, sender, path, iface, signal, params, widget) {
		// todo: look into .bind to access the label
		log("Signal received: WaveformChanged");
		const waveform = ebc.PnProxy.GetDefaultWaveformSync();
		const bw_mode = ebc.PnProxy.GetBwModeSync();
		var new_label = '';
		if (bw_mode == 0){
			new_label += 'G:';
		} else if (bw_mode == 1) {
			new_label += 'BW+D:';
		} else if (bw_mode == 2) {
			new_label += 'BW:';
		}

		new_label += waveform.toString();

		widget.set_text(new_label);
	}

	_write_to_sysfs_file(filename, value){
		try {
			// The process starts running immediately after this function is called. Any
			// error thrown here will be a result of the process failing to start, not
			// the success or failure of the process itself.
			let proc = Gio.Subprocess.new(
				// The program and command options are passed as a list of arguments
				['/bin/sh', '-c', `echo ${value} > ` + filename],
					// /sys/module/drm/parameters/debug'],

				// The flags control what I/O pipes are opened and how they are directed
				Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE
			);

			// Once the process has started, you can end it with `force_exit()`
			// proc.force_exit();
		} catch (e) {
			logError(e);
		}
	}

    _add_warm_indicator_to_main_gnome_menu() {
		// use the new quicksettings from GNOME 0.43
		// https://gjs.guide/extensions/topics/quick-settings.html#example-usage

		const FeatureSlider = GObject.registerClass(
		class FeatureSlider extends QuickSettings.QuickSlider {
			_init() {
				super._init({
					icon_name: 'weather-clear-night-symbolic',
				});

				this.filepath = "/sys/class/backlight/backlight_warm/brightness";
				this.max_filepath = "/sys/class/backlight/backlight_warm/max_brightness";

				// set slider to current value
				this.max_value = this._get_content(this.max_filepath);
				let cur_value = this._get_content(this.filepath);

				let cur_slider = cur_value / this.max_value;
				log(`Current value: ${cur_value} - ${cur_slider}`);
				this.slider.unblock_signal_handler(this._sliderChangedId);

				this.slider.block_signal_handler(this._sliderChangedId);
				this.slider.value = cur_slider;

				this._sliderChangedId = this.slider.connect('notify::value',
					this._onSliderChanged.bind(this));

				this._onSettingsChanged();

				// Set an accessible name for the slider
				this.slider.accessible_name = "Warm Backlight Brightness";
			}

			_onSettingsChanged() {
				// Prevent the slider from emitting a change signal while being updated
				this.slider.block_signal_handler(this._sliderChangedId);
				// this.slider.value = this._settings.get_uint('feature-range') / 100.0;
				this.slider.unblock_signal_handler(this._sliderChangedId);
			}

			_write_to_sysfs_file(filename, value){
				try {
					// The process starts running immediately after this
					// function is called. Any error thrown here will be a
					// result of the process failing to start, not the success
					// or failure of the process itself.
					let proc = Gio.Subprocess.new(
						// The program and command options are passed as a list
						// of arguments
						['/bin/sh', '-c', `echo ${value} > ` + filename],
							// /sys/module/drm/parameters/debug'],

						// The flags control what I/O pipes are opened and how they are directed
						Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE
					);

					// Once the process has started, you can end it with
					// `force_exit()`
					// proc.force_exit();
				} catch (e) {
					logError(e);
				}
			}

			_get_content(sysfs_file){
				// read current value
				const file = Gio.File.new_for_path(sysfs_file);
				const [, contents, etag] = file.load_contents(null);
				const ByteArray = imports.byteArray;
				const contentsString = ByteArray.toString(contents);

				return contentsString.replace(/[\n\r]/g, '');
			}

			_onSliderChanged() {
				// Assuming our GSettings holds values between 0..100, adjust
				// for the slider taking values between 0..1
				const percent = Math.floor(this.slider.value * 100);

				let relative = this.slider.value;
				const brightness = Math.round(relative * this._get_content(this.max_filepath));
				// log(`brightness: ${brightness}`);
				this._write_to_sysfs_file(this.filepath, brightness);
			}
		});

		const FeatureIndicator = GObject.registerClass(
		class FeatureIndicator extends QuickSettings.SystemIndicator {
			_init() {
				super._init();

				// Create the slider and associate it with the indicator, being sure to
				// destroy it along with the indicator
				this.quickSettingsItems.push(new FeatureSlider());

				this.connect('destroy', () => {
					this.quickSettingsItems.forEach(item => item.destroy());
				});

				// Add the indicator to the panel
				QuickSettingsMenu._indicators.add_child(this);

				// Add the slider to the menu, this time passing `2` as the second
				// argument to ensure the slider spans both columns of the menu
				QuickSettingsMenu._addItems(this.quickSettingsItems, 2);
			}
		});
		// initialize a new slider object
		this._indicator2 = new FeatureIndicator();
    }

	_change_bw_mode(new_mode){

		// change the mode BEFORE setting the waveform so a potential
		// bw-conversion will be properly handled
		// this._write_to_sysfs_file(
		// 	'/sys/module/rockchip_ebc/parameters/bw_mode',
		// 	new_mode
		// );
		ebc.PnProxy.SetBwModeSync(new_mode);

		if (new_mode == 0){
			this.bw_but_grayscale.visible = false;
			this.bw_but_bw_dither.visible = true;
			this.bw_but_bw.visible = true;
			this.m_bw_slider.visible = false;
			this.mitem_bw_dither_invert.visible = false;
			// use GC16 waveform
			// this._set_waveform(4);
			ebc.PnProxy.SetDefaultWaveformSync(4);
		} else if (new_mode == 1){
			// bw+dither
			this.bw_but_grayscale.visible = true;
			this.bw_but_bw_dither.visible = false;
			this.bw_but_bw.visible = true;
			this.m_bw_slider.visible = false;
			this.mitem_bw_dither_invert.visible = true;
			// use A2 waveform
			ebc.PnProxy.SetDefaultWaveformSync(1);
			// this._set_waveform(1);
		} else if (new_mode == 2){
			// bw
			this.bw_but_grayscale.visible = true;
			this.bw_but_bw_dither.visible = true;
			this.bw_but_bw.visible = false;
			this.m_bw_slider.visible = true;
			this.mitem_bw_dither_invert.visible = true;
			// use A2 waveform
			// this._set_waveform(1);
			ebc.PnProxy.SetDefaultWaveformSync(1);
		}

		// trigger a global refresh
		setTimeout(
			ebc.ebc_trigger_global_refresh,
			500
		);

	}

	_add_bw_buttons() {
		// add three buttons for grayscale, bw, bw+dithering modes

		// 1
		this.bw_but_grayscale.connect('activate', () => {
			this._change_bw_mode(0);
		});
		this._indicator.menu.addMenuItem(this.bw_but_grayscale);

		// 2
		this.bw_but_bw_dither.connect('activate', () => {
			this._change_bw_mode(1);
		});
		this._indicator.menu.addMenuItem(this.bw_but_bw_dither);

		// 3
		this.bw_but_bw.connect('activate', () => {
			this._change_bw_mode(2);
		});
		this._indicator.menu.addMenuItem(this.bw_but_bw);
	}

	_add_bw_slider() {
        // this.m_bw_slider = new PopupMenu.PopupBaseMenuItem({ activate: true });
		this._indicator.menu.addMenuItem(this.m_bw_slider);

        this._bw_slider = new Slider.Slider(0.5);
        this._sliderChangedId = this._bw_slider.connect('notify::value',
            this._bw_slider_changed.bind(this));
        this._bw_slider.accessible_name = _("BW Threshold");

        const icon = new St.Icon({
            icon_name: 'display-brightness-symbolic',
            style_class: 'popup-menu-icon',
        });
        this.m_bw_slider.add(icon);
        this.m_bw_slider.add_child(this._bw_slider);
        this.m_bw_slider.connect('button-press-event', (actor, event) => {
            return this._bw_slider.startDragging(event);
        });
        this.m_bw_slider.connect('key-press-event', (actor, event) => {
            return this._bw_slider.emit('key-press-event', event);
        });
        this.m_bw_slider.connect('scroll-event', (actor, event) => {
            return this._bw_slider.emit('scroll-event', event);
        });
	}

	_bw_slider_changed(){
		let bw_threshold;
		// transform to thresholds 1 to 7 in roughly similar-sized bins
		bw_threshold = 4 + Math.floor(this._bw_slider.value * 9);
		log(`new bw threshold: ${bw_threshold}`);
		this._write_to_sysfs_file(
			'/sys/module/rockchip_ebc/parameters/bw_threshold',
			bw_threshold
		);
	}

	_set_a1_waveform(){
		this._write_to_sysfs_file(
			'/sys/module/rockchip_ebc/parameters/default_waveform',
			1
		);
	}

	_set_waveform(waveform){
		this._write_to_sysfs_file(
			'/sys/module/rockchip_ebc/parameters/default_waveform',
			waveform
		);
	}

	_add_waveform_buttons(){
		let item;
		item = new PopupMenu.PopupMenuItem(_('A2 Waveform'));
		item.connect('activate', () => {
			this._set_waveform(1);
		});
		this._indicator.menu.addMenuItem(item);

		// item = new PopupMenu.PopupMenuItem(_('DU Waveform'));
		// item.connect('activate', () => {
		// 	this._set_waveform(2);
		// });
		// this._indicator.menu.addMenuItem(item);

		item = new PopupMenu.PopupMenuItem(_('GC16 Waveform'));
		item.connect('activate', () => {
			this._set_waveform(4);
		});
		this._indicator.menu.addMenuItem(item);

// 		item = new PopupMenu.PopupMenuItem(_('DU4 Waveform'));
// 		item.connect('activate', () => {
// 			this._set_waveform(7);
// 		});
// 		this._indicator.menu.addMenuItem(item);
	}

	_add_auto_refresh_button(){
		let filename = '/sys/module/rockchip_ebc/parameters/auto_refresh'
		let auto_refresh = this._get_content(filename);

		log(`add: auto refresh state: ${auto_refresh}`);

		if(auto_refresh == 'N'){
			this.mitem_auto_refresh = new PopupMenu.PopupMenuItem(_('Enable Autorefresh'));
		} else {
			this.mitem_auto_refresh = new PopupMenu.PopupMenuItem(_('Disable Autorefresh'));
		}
		this.mitem_auto_refresh.connect('activate', () => {
			this.toggle_auto_refresh();
		});

		this._indicator.menu.addMenuItem(this.mitem_auto_refresh);
	}

	toggle_auto_refresh(){
		log("Toggling atuo refresh");
		let filename = '/sys/module/rockchip_ebc/parameters/auto_refresh'
		let auto_refresh = this._get_content(filename);
		log(`toggle: auto refresh state: ${auto_refresh}`);

		if(auto_refresh == 'N'){
			auto_refresh = 1;
			this.mitem_auto_refresh.label.set_text('Disable Autorefresh');
		} else {
			auto_refresh = 0;
			this.mitem_auto_refresh.label.set_text('Enable Autorefresh');
		}

		this._write_to_sysfs_file(
			filename,
			auto_refresh
		);

	}

	_add_dither_invert_button(){
		let filename = '/sys/module/rockchip_ebc/parameters/bw_dither_invert'
		let bw_dither_invert = this._get_content(filename);

		if(bw_dither_invert == 'N'){
			this.mitem_bw_dither_invert.label.set_text('BW Invert On');
		} else {
			this.mitem_bw_dither_invert.label.set_text('BW Invert Off');
		}
		this.mitem_bw_dither_invert.connect('activate', () => {
			this.toggle_bw_dither_invert();
		});

		this._indicator.menu.addMenuItem(this.mitem_bw_dither_invert);
	}

	toggle_bw_dither_invert(){
		let filename = '/sys/module/rockchip_ebc/parameters/bw_dither_invert'
		let bw_dither_invert = this._get_content(filename);
		log(`Toggling dither invert (is: ${bw_dither_invert})`);

		if(bw_dither_invert == 0){
			bw_dither_invert = 1;
			this.mitem_bw_dither_invert.label.set_text('BW Invert Off');
		} else {
			bw_dither_invert = 0;
			this.mitem_bw_dither_invert.label.set_text('BW Invert On');
		}
		log(`new value: ${bw_dither_invert})`);

		this._write_to_sysfs_file(
			filename,
			bw_dither_invert
		);
	}

	add_refresh_button(){
		this._trigger_refresh_button = new TriggerRefreshButton();
		Main.panel.addToStatusArea(
			"PN Trigger Global Refresh",
			this._trigger_refresh_button,
			-1,
			'center'
		);
	}

	add_panel_label(){
		this.panel_label = new St.Label({
			text: "DADA",
            y_expand: true,
            y_align: Clutter.ActorAlign.CENTER,
        });
		Main.panel.addToStatusArea(
			"Waveform Status Label",
			this.panel_label,
			-1,
			'center'
		);
	}

    enable() {
        log(`enabling ${Me.metadata.name}`);

		this.add_refresh_button();
		// this.add_panel_label();

		// ////////////////////////////////////////////////////////////////////
		this._topBox = new St.BoxLayout({ });

		// Button 1
        let indicatorName = `${Me.metadata.name} Indicator`;

        // Create a panel button
        this._indicator = new PanelMenu.Button(0.0, indicatorName, false);

        // Add an icon
        let icon = new St.Icon({
            //gicon: new Gio.ThemedIcon({name: 'face-laugh-symbolic'}),
            gicon: new Gio.ThemedIcon({name: 'org.gnome.SimpleScan-symbolic'}),
            style_class: 'system-status-icon'
        });
        // this._indicator.add_child(icon);

		this._topBox.add(icon);

		// Add the label
        // this._indicator.add_child(this.panel_label);
		ebc.ebc_subscribe_to_waveformchanged(this.onWaveformChanged, this.panel_label);

        this._topBox.add_child(this.panel_label);
        this._indicator.add_child(this._topBox);
		// this._indicator.label_actor = this.panel_label;
		// this._indicator.add_actor(this.panel_label);

        // `Main.panel` is the actual panel you see at the top of the screen,
        // // not a class constructor.
        Main.panel.addToStatusArea(
			indicatorName,
			this._indicator,
			-2,
			'center'
		);

		let item;
		item = new PopupMenu.PopupMenuItem(_('Rotate'));
		item.connect('activate', () => {
			this.rotate_screen();
		});
		this._indicator.menu.addMenuItem(item);

		this._add_warm_indicator_to_main_gnome_menu();
		this._add_bw_buttons();
		this._add_bw_slider();
		this._add_dither_invert_button();
		this._add_auto_refresh_button();
		this._add_waveform_buttons()

		// activate default grayscale mode
		this._change_bw_mode(0);
    }

	_get_content(sysfs_file){
		// read current value
		const file = Gio.File.new_for_path(sysfs_file);
		const [, contents, etag] = file.load_contents(null);
		const ByteArray = imports.byteArray;
		const contentsString = ByteArray.toString(contents);

		return contentsString.replace(/[\n\r]/g, '');
	}

    // REMINDER: It's required for extensions to clean up after themselves when
    // they are disabled. This is required for approval during review!
    disable() {
        log(`disabling ${Me.metadata.name}`);

        this._indicator.destroy();
        this._indicator = null;
        this._m_warm_backlight_slider.destroy();
        this._m_warm_backlight_slider = null;
    }

	rotate_screen(){
		log('rotate_screen start');
    	// let state = get_state();
    	// let logical_monitor = state.get_logical_monitor_for(builtin_monitor.connector);
		// log(logical_monitor.transform);
		this.rotate_to("left-up");

	}

	rotate_to(orientation) {
        log('Rotate screen to ' + orientation);
        let target = Orientation[orientation];
        try {
            GLib.spawn_async(
                Me.path,
                ['gjs', `${Me.path}/rotator.js`, `${target}`],
                null,
                GLib.SpawnFlags.SEARCH_PATH,
                null);
        } catch (err) {
            logError(err);
        }
    }
}


function init() {
    log(`initializing ${Me.metadata.name}`);

    return new Extension();
}
