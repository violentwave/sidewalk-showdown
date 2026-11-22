## Summary

<!-- What changes, and why. Link the issue or audit this addresses. -->

## Type of change

- [ ] Gameplay / simulation data (damage, timings, hitboxes, knockback, movement, collision, buffers, cancels, invuln, hitstop, round rules)
- [ ] Presentation only (clips, cels, cadence, scale, VFX, HUD)
- [ ] Art / assets
- [ ] Tests or CI
- [ ] Docs only

> Gameplay changes and presentation-only changes should be separate PRs. If this
> touches fighter simulation, call out the exact values and files changed below.

## Test evidence

<!-- Paste the actual output, not a claim. Every suite must pass. -->

```text
combat_test:           ... checks, ... failure(s)
round_flow_test:       ... checks, ... failure(s)
character_select_test: ... checks, ... failure(s)
stage_select_test:     ... checks, ... failure(s)
stage_floor_test:      ... checks, ... failure(s)
locomotion_speed_test: ... checks, ... failure(s)
cpu_test:              ... checks, ... failure(s)
combo_test:            ... checks, ... failure(s)
combo_fuzz_test:       ... checks, ... failure(s)
stun_breaker_test:     ... checks, ... failure(s)
the_clip_test:         ... checks, ... failure(s)
serialization_test:    ALL PASS (exit 0)
b6_landing_whiff_test: ... checks, ... failure(s)
ui_flow_test:          ... checks, ... failure(s)
settings_test:         ... checks, ... failure(s)
ui_assets_test:        ... checks, ... failure(s)
ui_typography_test:    ... checks, ... failure(s)
select_screens_test:   ... checks, ... failure(s)
results_flow_test:     ... checks, ... failure(s)
air probe:            metrics only, job must still pass
```

- [ ] All nineteen CI suites run locally with the commands in `README.md`
- [ ] Rendered review done for visual changes (note the captures/screens and both facings)

## Docs

- [ ] User-facing docs updated (`README.md`, `docs/KNOWN_ISSUES.md`, `docs/PHASE_STATUS.md`, `docs/PIXELORAMA_PIPELINE.md` as applicable)
- [ ] No doc needed (explain below)

## Screenshots (visual changes only)

<!-- Before/after or a capture of the new state. Required for animation, HUD, art, or stage changes. -->

## Landing

`main` is squash-merge-only; the guard reverts unassociated pushes. Merge with
**Squash and merge** after `tests` is green, then delete the branch.
