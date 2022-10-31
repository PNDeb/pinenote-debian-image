#!/usr/bin/env sh

# Run on pinenote

tar -cvz -f original-firmware.tar.gz fw_bcm43455c0_ag_cy.bin nvram_ap6255_cy.txt fw_bcm43455c0_ag_cy.bin nvram_ap6255_cy.txt BCM4345C0.hcd

scp root@pinenote:/usr/lib/firmware/brcm/original-firmware.tar.gz .
