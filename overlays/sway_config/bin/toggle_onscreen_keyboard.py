#!/usr/bin/env python

from pydbus import SessionBus
import os
import time

bus = SessionBus()

try:
    okb = bus.get("sm.puri.OSK0")
except Exception:
    os.system("nohup squeekboard &")
    time.sleep(1)
    okb = bus.get("sm.puri.OSK0")

okb.SetVisible(not okb.Visible)
