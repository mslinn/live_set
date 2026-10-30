# Reference Sets

Sets of Live that are checked in, so that they are the same for everyone who works on this
project. The demo sets Ableton ships are not: they are installed with Live, and they differ
from one computer to the next.

| Set | Live version | Why it is here |
| --- | --- | --- |
| `live_11/Fascination.als` | 11.3.13 | A Live 11 set with return tracks. None of the demo sets of Live 11 has one, so the Live 11 schema inferred from the demo sets cannot describe a return track. |
| `live_12/Fascination_12_converted_by_live Project/Fascination_12_converted_by_live.als` | 12.4.7 | The same set as Live 12 wrote it. Both reference sets are checked in, so the conversion down to Live 11 can be proved against the set Live 11 itself wrote, and the round trip can run without Live 12. |

## Provenance

`live_11/Fascination.als` comes from
[owenbush/ableton-inspector](https://github.com/owenbush/ableton-inspector), which is under the
MIT license. It is a set by a user of Live, not a demo set of Ableton.

`live_12/Fascination_12_converted_by_live Project/Fascination_12_converted_by_live.als` is that
same set, opened in Live 12 and saved. Live 12 saves a set as a project folder, and the set is
the `.als` file in it. The rest of the folder is what Live writes around the set, and is not
checked in.

## How the Live 12 set is made

Live has to be running to make it, and the set is made by opening the Live 11 set in Live 12 and
saving it. `bin/make_reference_set` does that:

```shell
bundle exec ruby bin/make_reference_set 12 Fascination_12_converted_by_live sets/live_11/Fascination.als
```

The tool opens the set in Live 12, waits for Live to say that it has loaded it, and saves it
under the name that was given. The set is written as the Live that is installed writes it, so a
set written by another build of Live 12 is not the same set. The set is checked in afterwards, by
hand:

```shell
git add "sets/live_12/Fascination_12_converted_by_live Project/Fascination_12_converted_by_live.als"
```

The tool needs the version of Live that is asked for to be installed, and it needs the GUI
harness, which is a development dependency of this project.

## The samples of these sets

The samples of `live_11/Fascination.als` are not in the repository, and the Live 12 version
refers to them by their absolute paths on the machine it was saved on. The examples that read
these sets read the references to the samples, not the samples themselves.
