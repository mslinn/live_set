# `Live_set` [![Gem Version](https://badge.fury.io/rb/live_set.svg)](https://badge.fury.io/rb/live_set)

This program can:

1. Report the version compatibility of an Ableton Live set.
2. Make a copy of an Ableton Live 12 set and save to Live 11 format.
3. Detect environmental problems, for example unwanted directories called `Ableton Project Info` in parent directories.
4. Detect sets that are too large to be frozen, which means they are too large to transfer to Push 3 Standalone.
5. Detect tracks that are not frozen, which means they should not be transferred to Push 3 Standalone.

This program has successfully converted the Ableton Live 12 demo project to Live 11.


## Installation

Simply type:

```shell
$ gem install live_set
```

If the above does not work because you need to install Ruby, please
[follow these instructions](https://www.mslinn.com/ruby/1000-ruby-setup.html).


## Usage

```text
$ live_set
Displays information about a Live set or converts a copy of a Live 12 set in Live 11 format.
Also verifies that 'Ableton Project Info' is in the same directory as the .als file,
and there is no parent directory with a directory of that name.

Syntax: live_set OPTIONS PATH_TO_ALS_FILE

Environment variables used in PATH_TO_ALS_FILE are expanded.

Options are:
  -11 Convert a copy of the Live 12 set to Live 11 format.
  -f Overwrite any existing Live 11 set.
  -h Display this help message.

Example:
  live_set -11 -f $path/to/my_set.als
```

### Report

Report the version of the Ableton Live set:

```text
$ live_set $path/to/my_set.als
/mnt/c/media/Ableton/Projects/fu Project/fu.als
  Created by Live v11.0_11300
  Major version 11.0_11300
  Revision 5ac24cad7c51ea0671d49e6b4885371f15b57c1e
  SchemaChangeCount 3
Tracks:
  Drums / complete
  Bass
  Guitar
  Horns
  Keys
  Vocal Backing
  Vocal Lead
  Strings
```


### Convert

Make the Live 12 set compatible with Live 11 and save as `path/to/my_set_11.als`:

```shell
$ live_set -11 -f path/to/my_set.als
```


## Development

After checking out this git repository, install dependencies by running `bin/setup`:

```text
$ git clone https://github.com/mslinn/live_set
$ cd live_set
$ bin/setup
$ code .  # Run Visual Studio Code
```


### Run the Tests

```text
$ bundle exec rake test
```


### Debug run

Define the `VO_DEBUGGING` environment variable so the code is loaded from the project
instead of attempting to load the `live_set` gem.

```shell
$ VO_DEBUGGING=true ruby exe/live_set /path/to/my_set.als
```

### Interactive Session

The following will allow you to experiment:

```shell
$ bin/console
```


### Local Installation

To install this gem onto your local machine, type:

```text
$ bundle exec rake install
```


### To Release A New Version

To create a git tag for the new version, push git commits and tags,
and push the new version of the gem to https://rubygems.org, type:

```shell
$ bundle exec rake release
```


## Contributing

Bug reports and pull requests are welcome at https://github.com/mslinn/live_set.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
