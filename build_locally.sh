#!/bin/bash
./prep_00_get_kernel_files.sh && ./prep_03_custom_debs.sh &&  ./prep_05_get_external_files.s
./build.sh
