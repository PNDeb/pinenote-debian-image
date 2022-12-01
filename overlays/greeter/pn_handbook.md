# Welcome

## Introduction

Lorem Impsum

If you want to improve this text, merge requests are very very much appreciated!
(https://github.com/m-weigand/pinenote-debian-recipes/blob/mw_image/overlays/greeter/greet.html")[Improve here]

## Getting started

* User/Password: You are logged in as user "user" with password "1234". sudo is
  activated. We suggest to set a root password: First, "sudo su - root" and
  then "passwd"</li>

## How do I

* Read a book/pdf: Koreader is already installed and should be registered for corresponding file types

## What is not working?


## EBC Kernel Driver

### Waveforms

* the **default_waveform** parameter controls which waveform is used. Based on
  information from include/drm/drm_epd_helper.h, the integer values are
  associated with the following waveforms:

		0: @DRM_EPD_WF_RESET: Used to initialize the panel, ends with white
		1: @DRM_EPD_WF_A2: Fast transitions between black and white only
		2: @DRM_EPD_WF_DU: Transitions 16-level grayscale to monochrome
		3: @DRM_EPD_WF_DU4: Transitions 16-level grayscale to 4-level grayscale
		4: @DRM_EPD_WF_GC16: High-quality but flashy 16-level grayscale
		5: @DRM_EPD_WF_GCC16: Less flashy 16-level grayscale
		6: @DRM_EPD_WF_GL16: Less flashy 16-level grayscale
		7: @DRM_EPD_WF_GLR16: Less flashy 16-level grayscale, plus anti-ghosting
		8: @DRM_EPD_WF_GLD16: Less flashy 16-level grayscale, plus anti-ghosting

* (side note): Based on information from drivers/gpu/drm/drm_epd_helper.c, the
  Pinenote uses eps lut form 0x19, which associated waveform types with the
  luts stored in the file as:

		.versions = {
		    0x19,
		    0x43,
		},
		.format = DRM_EPD_LUT_5BIT_PACKED,
		.modes = {
		    [DRM_EPD_WF_RESET]  = 0,
		    [DRM_EPD_WF_DU]     = 1,
		    [DRM_EPD_WF_DU4]    = 7,
		    [DRM_EPD_WF_GC16]   = 2,
		    [DRM_EPD_WF_GL16]   = 3,
		    [DRM_EPD_WF_GLR16]  = 4,
		    [DRM_EPD_WF_GLD16]  = 5,
		    [DRM_EPD_WF_A2]     = 6,
		    [DRM_EPD_WF_GCC16]  = 4,
		},

  For example, if you want to inspect/modify the A2 waveform, this corresponds
  to the 7th waveform in the lut file (index 6), but is activated via
  **default_waveoform** by writing value 1.
