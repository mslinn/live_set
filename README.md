# `Live_set` [![Gem Version](https://badge.fury.io/rb/live_set.svg)](https://badge.fury.io/rb/live_set)

<blockquote style="border: 1px solid currentColor; padding: 12px; border-radius: 4px;">
  This project is in a state of flux.
  The published gem was a proof of concept.
  All code and comments are aspirational until this message is deleted.
  The current code probably does not work and the docs are a mess.
  Come back real soon now, and things should be much better!
</blockquote>


## Capabilities

This software can:

1. Make a copy of an Ableton Live 12 set and save to Live 11 format.

2. Report the version compatibility of an Ableton Live set.

3. Detect environmental problems, for example unwanted directories called
   `Ableton Project Info` in parent directories.

4. Display the location and size of the samples in each track.

5. Show changes that are made to a Live set.

6. Show changes persisted to file storage each time a Live session is saved in
   real time.

7. Clearly show if a Live set is ready to be transferred to a P3S, and what
   needs to be changed if not.

   a. Detect sets that are too large to be frozen, which means they are too
   large to transfer to P3S.

   b. Detect tracks that have non-Ableton plugins are not frozen, which means
   they are not ready to be transferred to
   P3S.

   c. Detect group tracks that have non-Ableton plugins. A group track cannot be
   frozen unless Options.txt allows it.  The plugin has to be removed from the
   group&rsquo;s chain, or the group has to be bounced to another track and then
   be disabled.

   d. Show clips that are have not been collected within the set&rsquo;s project
   directory.

8. Report the samples in frozen tracks. During playback, a frozen track
   *shadows* the track with the editable material.  Both tracks are reported.


## Current Project Status

The demo programs provided with each version of Ableton Live are an important
source of information.

The published gem converted the Ableton Live 12 demo project to Live 11, with
known errors. Other functionality has been tested with Live 8.6 session files.

The up-conversion the published gem performed was a selective removal: it wrote the
Live 11 version strings, removed the three elements that Live 11 does not have,
and copied everything else through unchanged. Two elements that Live 11 does
have were translated rather than removed, because Live 12 names them differently
— see
[docs/dev/live_11_12_diff.md](docs/dev/live_11_12_diff.md#the-elements-the-two-versions-name-differently).

The down-conversion in this repository does not produce a set that Live 11
opens: the lane types are one of the problems (see
[`docs/TODO.md`](docs/TODO.md) N42).


## Push 3 Standalone (P3S)

See [Push 3 Standalone (P3S)](docs/p3s.md) for features provided by this Ruby
gem for supporting the P3S.


## Installation

Type:

```shell
$ gem install live_set
```

If the above does not work because you need to install Ruby, please [follow these
instructions](https://www.mslinn.com/ruby/1000-ruby-setup.html).


## Upgrading

Type:

```shell
$ gem upgrade live_set
```


## Commands

The following commands are provided:

- [`als_delta`](docs/commands/als_delta.md) (used when Live is running) shows
  changes to a session file each time the session is saved.
- [`als_diff`](docs/commands/als_diff.md) compares two sets element by element,
  and prints the differences.
- `als_nodes` prints the nodes of an XML document that an XPath expression finds.
- `als_release_notes` prints the release notes of a version of Live as markdown.
- `als_report` writes a report of a Live set in markdown.
- `als_to_version` converts a Live set to another version of the format.
- `als_to_xsd` reads one or more Ableton Live sets and generates an XSD.
- `als_validate` checks that a session file conforms to an XSD schema.

The examples of how to use each command assume the `$live_set` environment variable points to an ALS file, for example:

```shell
live_12_demos="$live_reference_sets/sets/live_12/demo/projects_and_als/"
live_set="$live_12_demos/Chuck Sutton - Patience (Live 12 Suite Demo).als"

als_sample_command "$live_set"
```


## Live Experimental Features

Ableton Live can be configured to enable experimental and unsupported features
through an `Options.txt` file in its Preferences folder. For example,
`-_GroupTrackFreeze` allows a group track to be bounced as though it were a
track.

`als_report` does not search for a file called `Options.txt`.

TODO I am uncomfortable with the following conclusion, depending on the state of
the XML file. If an ALS file is generated somehow that has a frozen group track,
we should respect the XML file. We need to follow through and look in this
project for contradictory docs and code, and fix them.

TODO One of the experimental options that might be in effect when saving a Live
set is the ability to save a frozen group track. The all of the group-related
data should be converted when upgrading between versions to maintain the
integrity of the data, unless we learn about a problem from doing that. Also see
[docs/dev/als_notes.md](docs/dev/als_notes.md#the-optionstxt-hidden-option).


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

Define the `VO_DEBUGGING` environment variable so the code is loaded from the project instead of attempting to load the
`live_set` gem.

```shell
$ VO_DEBUGGING=true ruby exe/als_report /path/to/my_set.als
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

To create a git tag for the new version, push git commits and tags, and push the new version of the gem to
https://rubygems.org, type:

```shell
$ bundle exec rake release
```


## Contributing

Bug reports and pull requests are welcome at https://github.com/mslinn/live_set.


## License

The gem is provided as [source-available, noncommercial license](LICENSE.md).  Commercial use, and use in court-case
investigations, require paid licenses.
