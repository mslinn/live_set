# `als_delta`

## Help Message

```html
$ als_delta -h
als_delta: Shows changes to an .als file each time a session file is saved.
Press any key to make a backup of the current version of the `als` file and
compare it with previous version.

Backups can be kept by using the -k option. By default, only one backup is
used, and it is deleted when the process exits.

Syntax: als_delta [OPTIONS] PATH_TO_ALS_FILE

Environment variables used in PATH_TO_ALS_FILE are expanded.

OPTIONS can be specified anywhere on the command line:
  -h, --help
          Display this help message.
  -k      Keep each backup and timestamp it, instead of overwriting the previous backup.
  -l LOGLEVEL, --log LOGLEVEL
          Set the log level. Allowable values are:
          DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN.

Example (references an environment variable called "path"):
  $ als_delta "$path/to/my_set.als"
```

## Example Usage

```shell
$ als_delta "$live_set"
Backing up Live set to '/mnt/f/work/ableton/live_reference_sets/sets/live_12/demo/projects_and_als/Chuck Sutton - Patience (Live 12 Suite Demo)_backup.als'
Press any key to display the changes to the Live set XML file, or press Esc to exit.

There were no changes to the saved live set.
Press any key to display the changes to the Live set XML file, or press Esc to exit.

Deleting '/mnt/f/work/ableton/live_reference_sets/sets/live_12/demo/projects_and_als/Chuck Sutton - Patience (Live 12 Suite Demo)_backup.als'
```
