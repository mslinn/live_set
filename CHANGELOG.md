# Change Log

## 0.2.5 2026-10-21

* Changed license from MIT to source-available non-commercial.
* Added `bin/validate_asd`.
* Added `generate_xsd` command.
* Added `validate_asd` command.
* Improved `README.md`.
* Made parsing of sessions from Ableton Live 8.2.6 more robust.
* Added `spec.platform` to `live_set.gemspec` because `RubyGems.org` now
  requires it.
* Updated `bin/setup` so it complies with recent changes to `bundle`.
* Improved output so it is more compact and more precise.
* Merged pull request from @uones regarding:

  * Handling MidiTrack
  * Ignoring missing sample paths
  * logging changes

* Replaced logging changes from @uones with standard Ruby logging and removed
  unnecessary debug messages.

## 0.2.4

* Reports the absolute directory of errant audio clips.


## 0.2.3

* Improved warning messages.


## 0.2.2

* Displays `Ready for transfer to Push 3 Standalone` in green if Live set is ready,
  or displays the reasons for not being ready in red.

## 0.2.1

* Corrected missing help method for the `live_set` command.
* Prompts user if they want the extra directory renamed to `Ableton Project Info-`.


## 0.2.0

* Checks `Ableton Project Info` validity all up the directory tree.
* Reports the clips in the set, and their sizes.
* Generates a warning if the total size of the clips might cause freezing to fail.


## 0.1.0

* Initial release.
