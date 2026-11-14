# Commands

Each command is implemented as a class method called `run` on the class that
implements it, and the class is named after the command:

[als_report](als_report.md)             [`AlsReport#run`](../../lib/als_report/als_report.rb)
[als_delta](als_delta)                  [`AlsDelta#run`](../../lib/als_delta/als_delta.rb)
[als_to_version](als_to_version)        [`AlsToVersion#run`](../../lib/als_to_version/als_to_version.rb)
[als_to_xsd](als_to_xsd)                [`AlsToXsd#run`](../../lib/als_to_xsd/als_to_xsd.rb)
[als_validate](als_validate)            [`AlsValidate#run`](../../lib/als_validate/als_validate.rb)
[als_nodes](als_nodes)                  [`AlsNodes#run`](../../lib/als_nodes/als_nodes.rb)
[als_diff](als_diff)                    [`AlsDiff#run`](../../lib/als_diff/als_diff.rb)
[als_release_notes](als_release_notes)  [`AlsReleaseNotes#run`](../../lib/als_release_notes/als_release_notes.rb)

The executables in `exe/` call the class methods. Each class also parses its
own options, in its `*_options.rb` file, and displays its own help.
