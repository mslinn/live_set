# Push 3 Standalone (P3S)

Importing Ableton Live project files to the P3S is a painful process. Debugging
can be frustrating. You sometimes feel like you are spending more time
struggling with the technology than you are getting useful work done.

The `als_report` command from `Live_set` reports on the status of an Ableton
Live set and gives a go/no go signal for transmission to a P3S. The remainder of
this document describes the type of problems that `als_report` looks for.

## Reported Problems

A Live Set may fail to open, open with missing content, or open but behave
differently on Push 3 Standalone for several reasons. The `als_report` command
reports the ones it can see, and says what to do about each of them.

1. Incompatible Live Versions

   P3S runs an embedded version of Live internally. The earliest compatible version
   of a Live set that can be transferred to a P3S is Live 11. Live 12 sets can also
   be transferred; the latest supported version is Live 12.4.

    The oldest version of Live the P3S Standalone can load a set of is Live
    11.3.  The P3S Standalone runs a version of Live of its own, and it loads a
    set only when the set was made with that version of Live or with a later
    one: a P3S Standalone that has Live 12.3 in it cannot load a set that was
    made with Live 12.4. The version of Live the P3S Standalone has is not known
    to the report, so the oldest version it supports is the one that is checked.

2. Third-Party Plugins (VST / VST3 / AU)

    An unfrozen track will cause a error (or fail to produce sound) on a P3S if
    it relies on an unsupported device or routing that the P3S does not support.

    The P3S runs a customized version of Ableton Live that does not support
    non-Ableton devices, such as VST2, VST3, Audio Units (AU), or CLAP plugins.

    If an unfrozen track uses any of these non-Ableton plugins, the P3S will
    throw a "Missing Plugin" or "Plugin not available" error when loading the
    set. The track will either be completely silent or replaced by a blank
    placeholder device.

    Freezing a track renders the it to an audio file, making a permanent
    recording of the plugin's sound processing.  Frozen tracks are easily played
    back by the P3S, so the plugin can be ignored while the track is frozen.

    If any non-Ableton plugin is not on a frozen track then the `als_report`
    command includes a clear explanation of the problem in its generated report.
    A MIDI track has the same devices as an audio track, and the same problems:
    a plug-in on a MIDI track has to be frozen as well.

3. Missing Samples or Media

    Transferring just the .als leaves the files it refers to behind. The whole
    project has to be transferred, or the set has to be saved with Collect All
    and Save. The report counts the clips of the set that have not been
    collected.

4. Packs

    A set that plays a file of a pack refers to the pack, and the pack has to be
    installed for the file to be found.  Samples from packs require those packs
    to be installed on the Push as well.

    A pack that is not installed does not stop the set from loading, and the set
    plays: the content of the pack does not play. There is no way to probe the
    P3S, so what is installed on it is not known here, and a set that refers to
    a pack can only be classified as *probably* ready. The report says what
    could not be checked, and it names the packs the set refers to that are not
    installed on the computer the report was made on.

5. Incompatible or Overloaded Max for Live (M4L) Devices

    P3S supports Max for Live, but it has a weaker CPU than a modern desktop
    computer. M4L devices that require a lot of processing might not work properly on a
    P3S.

    Freezing an M4L device on a computer before transferring to the P3S renders
    the M4L device output to an audio track. This removes the need for heavy CPU
    processing at playback time.

    The report provides advises for every M4L device in a set indicating that
    the device might not function properly.

6. The Arrangement View

    Sets can load and play, but Arrangement View editing is not supported in
    Standalone Mode; the Push is optimized for the Session View. A set that has
    no clip in the session view is an empty set as far as the P3S is concerned.

7. Capacity

    A set may exceed the available CPU, memory, or track capacity for the Live edition running on the Push. A set of
    more than 2 GB is incompatible with the P3S Standalone.

## Known Problems the Report Does Not Check

The Licence of the Content

    Whether the sound or the device of a set is available under the Live licence
    that the P3S Standalone is authorized with cannot be checked here. A set that
    uses content the licence does not cover loads and plays, but the content does
    not play. The report does not check this.

Desktop-Specific External Audio Routing

    If a track's Audio From is set to "Ext. In" and routed to a specific channel of
    a desktop audio interface (e.g., "Ext. In: 3/4" from a Focusrite Scarlett), that
    routing will not exist on the P3S.

    The track will load, but it will be silent because the expected input hardware
    isn't there.

    Freezing the track makes the Live set compatible with the P3S. Recording the
    external audio into a clip, then freezing the track converts an external input
    dependency into a self-contained audio clip and makes the Live set compatible
    with the P3S.

    The report does not check this yet.
