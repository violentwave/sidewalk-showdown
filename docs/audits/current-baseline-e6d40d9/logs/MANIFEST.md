# Current-baseline log manifest

Baseline: `e6d40d9607a0f0e3fc4a3be23ed592dbd9d43eda` (`origin/main`).
Environment: Godot `4.7.2.stable.official.ed1daf0bf`, headless, isolated detached
worktree created from current `origin/main`.

Commands were run with `set +e`, capturing `$?` directly after each Godot
process. Counts were extracted only after the exit code was captured; no
`grep`/`tail` pipeline status was used as a substitute for the Godot exit code.

| Artifact | Command | Exit | Result |
|---|---|---:|---|
| `import.log` / `import_exit.txt` | `godot --headless --path game --import` | 0 | Fresh import completed |
| `combat_test.log` | `godot --headless --path game --script res://tests/combat_test.gd` | 0 | 124 PASS, 0 FAIL |
| `round_flow_test.log` | `godot --headless --path game --script res://tests/round_flow_test.gd` | 0 | 30 PASS, 0 FAIL |
| `air_probe.log` | `godot --headless --path game --script res://tests/air_probe.gd` | 0 | Metrics-only report |
| `knockdown_probe.log` | external `knockdown_probe.gd` | 0 | B1/B2 reproduction |
| `buffer_probe.log` | external `buffer_probe.gd` | 0 | B3 reproduction |
| `corner_trade_probe.log` | external `corner_trade_probe.gd` | 0 | B4/B10 reproduction |
| `wakeup_probe.log` | external `wakeup_probe.gd` | 0 | B7 reproduction |
| `b6_meter_probe.log` | external `b6_meter_probe.gd` | 0 | B6 follow-up |

`exit_codes.txt` contains the suite exit codes; `probe_exit_codes.txt` contains
the external probe exit codes.

The external probe scripts were intentionally kept outside the repository. They
instrumented no tracked game files; they loaded `MatchRoot.tscn` and called the
real fighter/match methods from `SceneTree` scripts. The logs are preserved here
for reproducibility, but the probe scripts are not part of the game build.
