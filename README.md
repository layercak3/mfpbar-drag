# mfpbar-drag

This is a motherfucking progress bar with support for dragging.

Differences:
* The seek now occurs when the left mouse button is pressed, not when it's
  released.
* When the left mouse button is pressed, an exact seek is used. Then, any seeks
  triggered by dragging are keyframe seeks by default. No seek is performed when
  releasing the button.
* The script message 'exact-drag-seek yes' can be used to enable exact seeks
  when dragging, and 'exact-drag-seek no' to use keyframes again. You could
  for example observe the hr-seek property for changes in another script and
  change drag seeking behaviour according to the value of hr-seek.
* `--input-builtin-dragging` is disabled while the progress bar is active (i.e.
  when the mouse is in the proximity range).
* `--cursor-autohide` is disabled while the progress bar is active.
* `MBTN_LEFT_DBL` is ignored while the progress bar is active because I use that
  as an alternate fullscreen toggle.
* The `hover_lock_to_chapter_time` option controls whether hovering over a
  chapter diamond should lock the preview to displaying the chapter time (middle
  of the diamond).
* The OSC margins are disabled while the bar is hidden and reduced to the height
  of the minimized bar when minimized.
* The script message 'inhibit yes' can be used to prevent the bar from becoming
  visible, and 'inhibit no' undoes this. You could for example disable the bar
  while your image detection script detects an image. The script counts the
  number of inhibits ('inhibit yes' increments by one, 'inhibit no' decrements
  by one) and uninhibits when the count is zero. This allows multiple scripts
  to control bar visibility at the same time while ensuring the bar becomes
  visible only when all scripts have restored visibility.
* If all chapter titles are empty strings, space isn't allocated for the chapter
  title line.

The original script can be found at
https://codeberg.org/NRK/mpv-toolbox/src/branch/master/mfpbar and the original
README is copied verbatim below.

---

# mfpbar

This is a MotherFucking Progressbar.

<div align="center">
<a href="https://webm.red/view/WZhH.webm"><img width="60%" src="https://images2.imgbox.com/cb/e5/HcbVn5lT_o.png"></a>
<a href="https://webm.red/view/WZhH.webm"><p>[Click for video preview]</p></a>
</div>

## Features

The goal of this project is to be a progress-bar with minimal visual-clutter,
features, as well as code-size.

* Basic progress-bar functionality.
* Cached indicator (can be disabled).
* Chapter markers (can be disabled).
* Basic hover-preview via [thumbfast][tf].

## Installation

* Put [mfpbar.lua](mfpbar.lua) inside your `~~/scripts` directory,
  where `~~` is your [mpv config dir](https://mpv.io/manual/master/#files).
* Put `osc=no` in your `mpv.conf`.

* Optionally install [thumbfast][tf] for preview support.
* It is also recommended (but not required) to set `osd-bar=no` in your
  `mpv.conf`.

NOTE that `mfpbar` requires mpv version `0.33.0` or above.

[tf]: https://github.com/po5/thumbfast

## Configuration

`mfpbar` can be configured by creating a `mfpbar.conf` file inside
`~~/script-opts` directory. All the available options and their defaults are
documented in the example [mfpbar.conf](./mfpbar.conf) file.

Additionally, `mfpbar` registers a `maximize` key binding which you can bind in
your `input.conf`. For example, the following binds <kbd>Space</kbd> to pause
and simultaneously maximize the bar:

    Space cycle pause; script-binding mfpbar/maximize

You can also specify a non-default timeout (in seconds) via using script
message. The following will maximize the bar for 2.4 seconds when pressing
<kbd>TAB</kbd>.

    TAB  script-message-to  mfpbar maximize 2.4

## Motivation

After [uosc][] went full bloat in version 4, I decided that I'd write my own
which contains only the functionality that I need.
Needless to say, this mimics the older `uosc`'s progress-bar quite a lot in
terms of visuals.

The name of this project is a homage to the [motherfucking
website](https://motherfuckingwebsite.com/), which seemed quite appropriate
since my goal was to just get a minimal clutter-free progress-bar.

[uosc]: https://github.com/tomasklaen/uosc
