# TODO

The outstanding work of the `live_set` gem, and nothing else.

Every item has an identifier, and the identifiers are stable: the code, the
specs and the documents cite them, so an identifier is never reused, and it
never changes what it means. When an item is completed its entry is deleted,
and anything worth keeping is written up in another Markdown file in `docs/`
and/or the code itself.

The plan for the Live 12 → Live 11 conversion is `docs/fix_plan2.md`. That
document holds the steps of that plan and the work list of the down direction.
This file holds the outstanding work of the gem as a whole, and the two overlap
where an item belongs to the conversion: **T1** is the contract the conversion
has to meet, and **N42** is the lane `Type` risk the conversion carries. Such
an item is described here, and the plan and the code refer to it by its
identifier.

This project was developed for WSL, which implies Windows 10 or 11.
It performs round-trip validation of Live 11 -> Live 12 -> Live 11 sets
using `live_set -11`, followed by running Ableton Live under Windows.


## Reverse Engineering Work

[`gui_harness`](https://github.com/mslinn/gui_harness) is the basis for the
reverse engineering of the Ableton Live XML format.

At a high level, the GUI harness does the following:

1. Launch a live app
2. Inspect the process-owned windows
3. Read visible dialog text
4. Classify the dialog family
5. Dismiss the correct control
6. Report the outcome.


### Outstanding work

The `live_set -11` converter is incomplete and has bugs. The documentation has
errors and omissions. See TODO and FIXME comments.


#### GH1. Real round-trip equivalence

The round-trip test should assert more than `no error` and `End
ExchangeDocument`; it should confirm the converted set opens cleanly, preserves
structure, and does not trigger restore or crash behavior.

#### GH2. Recovery-state fixtures

The harness and parser should be pinned against real recovery and crash cases,
including clean exits, restore prompts, recovery-file moves, and `Restore
Document: Rejected by the user` behavior.

#### GH3. Outcome model and dialog matrix

The harness result model should consistently report `loaded`, `crashed`,
`blocked`, or `unknown`, and each dialog family should correspond to a known
dismiss action and pass/fail classification.

### Other open project work

#### T1. XML-level validation of the Live 11 conversion

The conversion contract should be made explicit by asserting the supported lane types, the expected `ContentLanes` and `ExpressionLanes` structure, and the required absence of unsupported Live 12-only nodes.

#### T5. Tighten conversion check names and scope

The existing specs should be organized around the exact contract they prove: conversion output, Live compatibility, or harness parsing.

#### M11. `LiveScene` dead data path

`LiveScene` is constructed but never used in a meaningful way. This is dead code and should either be removed or turned into a real part of the model.

#### N36. `als_delta` compares against a backup, not the previous version

The first comparison is effectively against itself because the backup logic does not compare against the prior version in the first run.

#### N10. `LiveTracks#ready_for_p3s?` dead code

This helper is defined but not used; the inline `p3s_tx_msg` logic already covers the relevant behavior.

#### N37. Frozen-track clip reporting is confusing

The same clip can be encountered through both sequencers and reported more than once. The distinction between source and distinct files should be clarified.

#### N40. Group device chain reporting is incomplete

A group-level device blocking condition is reported on the group, but not on the member tracks that inherit the same signal path.

#### N41. Blocking device on group member is counted twice

A device on both a track and its group results in duplicated reporting for the same underlying problem.

#### N42. Unknown lane `Type` values may crash Live 11

The Live 12 lane numbering is not portable to Live 11, and the round-tripped set keeps lane `Type` values that Live 11 does not understand. This is the main unresolved compatibility risk.

#### N43. `FakeGroup` remains unverified

The claim that a `FakeGroup` routing wrapper exists has not been confirmed from the corpus examined so far.

#### N50. Known crash path missing as a failing regression

The current Live 11 crash behavior should be captured as a compact failing regression fixture before treating a fix as complete.
