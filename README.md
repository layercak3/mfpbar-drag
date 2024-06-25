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
your `input.conf`. For example, the following binds <kbd>RIGHT</kbd> to seek and
simultaneously maximize the bar:

    RIGHT seek 5; script-binding mfpbar/maximize

You can also specify a non-default timeout (in seconds) via using script
message. The following will maximize the bar for 3 seconds when pressing
<kbd>TAB</kbd>.

    TAB  script-message-to  mfpbar maximize 1.5

## Motivation

After [uosc][] went full bloat in version 4, I decided that I'd write my own
which contains only the functionality that I need.
Needless to say, this mimics the older `uosc`'s progress-bar quite a lot in
terms of visuals.

The name of this project is a homage to the [motherfucking
website](https://motherfuckingwebsite.com/), which seemed quite appropriate
since my goal was to just get a minimal clutter-free progress-bar.

[uosc]: https://github.com/tomasklaen/uosc
