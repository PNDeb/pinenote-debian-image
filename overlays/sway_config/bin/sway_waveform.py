#!/usr/bin/env python3
from enum import Enum
import pathlib

import i3ipc

class Waveform(Enum):
    RESET = 0
    A2 = 1
    DU = 2
    DU4 = 3
    GC16 = 4
    GCC16 = 5
    GL16 = 6
    GLR16 = 7
    GLD16 = 8


class BWMode(Enum):
    GREY = 0
    DITHERING = 1
    THRESHOLDING = 2

class Preset(Enum):
    A2_DITHERING = 0
    GC16_GREY = 1

presets = {
    Preset.A2_DITHERING: (Waveform.A2, BWMode.DITHERING),
    Preset.GC16_GREY: (Waveform.GC16, BWMode.GREY),
}

class EDCManager:

    def __init__(self):
        param_dir = pathlib.Path('/sys/module/rockchip_ebc/parameters/')
        self.default_waveform = param_dir / 'default_waveform'
        self.bw_mode = param_dir / 'bw_mode'

    def get_waveform(self) -> Waveform:
        return Waveform(int(self.default_waveform.read_text()))

    def set_waveform(self, waveform: Waveform):
        self.default_waveform.write_text(str(waveform.value))

    def get_bw_mode(self) -> BWMode:
        return BWMode(int(self.bw_mode.read_text()))

    def set_bw_mode(self, bw_mode: BWMode):
        self.bw_mode.write_text(str(bw_mode.value))

    def use_preset(self, preset: Preset):
        waveform, bw_mode = presets[preset]
        self.set_waveform(waveform)
        self.set_bw_mode(bw_mode)
        print('Using preset', preset)

class Monitor:
    def __init__(self):
        self.last_app_id = None
        self.edc_manager = EDCManager()
        self.conn = i3ipc.Connection()
        self.conn.on('window::focus', self.focus_change)

    def focus_change(self, i3conn, event):
        app_id = event.container.app_id
        print('focus change', app_id)
        if app_id != self.last_app_id:
            match app_id:
                case 'KOReader':
                    self.edc_manager.use_preset(Preset.GC16_GREY)
                case 'xournalpp':
                    self.edc_manager.use_preset(Preset.A2_DITHERING)
                case _:
                    self.edc_manager.use_preset(Preset.A2_DITHERING)
            self.last_app_id = app_id

    def run(self):
        try:
            self.conn.main()
        except KeyboardInterrupt:
            print('Exiting')

def main():
    m = Monitor()
    m.run()

if __name__ == '__main__':
    main()
