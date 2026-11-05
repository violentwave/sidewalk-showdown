# License Options — decision document

Status: **decision pending. Report-only; the project owner chooses.**
Nothing in this repo is licensed yet, so the default is **all rights reserved**
(copyright law grants no public rights by default). This document lays out the
three realistic options for a solo-developed, mature-rated game with
AI-generated art. It is not legal advice; have a lawyer review the choice before
selling anything.

## What is actually being licensed

Different parts of the project have different licensing realities:

| Asset | Notes |
|---|---|
| Game code (`game/scripts`, scenes, data) | Your code. The Godot Engine itself is MIT-licensed (keep its notices), but your project code can carry any license you choose. |
| Art / audio / writing | AI-generated art has **uncertain copyrightability**. In the US, the Copyright Office requires human authorship; prompts alone are generally not enough, while human arrangement/editing/compositing can be protected. Expect the art to be hard to enforce even if the repo says "all rights reserved". |
| Names / logo / characters | Protected (if at all) by **trademark**, not copyright. A LICENSE file does not create trademark rights. |
| Third-party assets | Fonts, sounds, and templates each keep their own licenses. The Godot default font (Noto Sans) is OFL; audit before shipping. |

Two cross-cutting facts:

- **AI provenance matters for every option.** Keep generation logs, prompts,
  model names/versions, and evidence of human editing. Some storefronts require
  AI-content disclosure, and an unprotectable-art project weakens the value of
  *any* exclusive license.
- **Mature content constrains distribution**, not copyright: payment processors,
  storefronts, and age-gating rules apply regardless of license.

## Option A — All rights reserved + NOTICE

Add a `LICENSE`/`NOTICE` saying "© 2026 <owner>. All rights reserved." The source
may remain publicly visible on GitHub (visibility is not a license), but nobody
may copy, modify, redistribute, or reuse it.

**Pros**
- Maximum control: no one can reuse characters, art, code, or the name.
- Simplest to understand and enforce; no compatibility questions.
- Keeps every commercial option open (publishing, ports, merch, sequels).
- Works with AI art's uncertain ownership: you are not promising rights you may
  not hold.

**Cons**
- No legal path for community fixes, mods, fan games, translations, or forks —
  even noncommercial ones. GitHub users can still *view* and fork under the ToS,
  but cannot lawfully run or build on the fork.
- Contributors cannot safely submit code without a separate CLA; drive-by PRs
  become a legal grey area.
- No ecosystem, no goodwill from the open-source/fighting-game community.
- Mature content plus "all rights reserved" makes fan art/fan games technically
  infringing, which can chill the exact community a trashy arcade parody wants.

**Best if:** the priority is commercial control and you do not want to manage a
community license.

## Option B — CC BY-NC 4.0 (creative content), code licensed separately

Put the creative work (art, writing, audio, maybe data) under
**Creative Commons Attribution-NonCommercial 4.0**, and keep the code under a
separate license (all rights reserved, or MIT if you want code contributions).

CC BY-NC allows sharing and adaptation for noncommercial purposes with
attribution. It is not a software license: CC itself recommends against using CC
licenses for code, which is why the code should stay separate.

**Pros**
- Explicitly welcomes fan art, fan games, mods, streams, and translations, as
  long as they are noncommercial and credited.
- Attribution builds the brand and keeps the canon visible.
- Irrevocable for users (you can stop offering the license for new versions, but
  already-granted rights persist), which is friendly to a community.
- Mature content is a natural fit for a noncommercial fan ecosystem.

**Cons**
- "NonCommercial" is legally fuzzy (ads, Patreon, monetized videos, bundle
  sales); expect questions and edge cases.
- You permanently give up the ability to stop noncommercial reuse of *those
  versions*; a future paid remaster can be forked and shared freely (though not
  sold).
- **AI-generated art may not be copyrightable at all**, so you may be "licensing"
  something you cannot enforce — and CC's attribution machinery assumes
  authorship.
- Mixed licensing (CC for content, another for code) confuses users and
  contributors; every asset needs correct labeling.

**Best if:** community growth, fan works, and goodwill matter more than
exclusive control, and you accept that the art is not strongly protectable.

## Option C — Proprietary, source-available

Keep all rights, but publish the source under a **source-available** license:
viewing, building, and noncommercial modding are allowed; commercial use,
redistribution of a competing build, and asset reuse are not. This is typically a
custom license or a standard source-available template (for example a
PolyForm-style noncommercial license), not an OSI open-source license.

**Pros**
- Transparency and moddability without giving away commercial rights.
- Keeps the door open for a paid release, DLC, ports, and licensing deals.
- Clearer than CC for code and mixed media; can be tailored to mature content
  (e.g. no sexual content involving characters presented as minors, no
  commercial reuse).
- Contributors can be handled with a CLA that keeps the commercial option open.

**Cons**
- Custom legal drafting is real work; a badly written license is worse than none.
- Not open source, so it will not satisfy OSI-oriented contributors or some
  package ecosystems.
- Still does not fix AI-art enforceability or trademark gaps.
- Adds support/moderation obligations: someone must answer license questions and
  police commercial misuse.

**Best if:** you want the code public for trust/modding but intend to sell the
game and keep exclusive commercial rights.

## Decision checklist

1. **Will the game be sold, and do you want to keep ports/DLC/merch exclusive?**
   Yes → A or C. No → B becomes viable.
2. **Do you want fan games and mods to be legal?**
   Yes, noncommercial only → B or C. No → A.
3. **Do you want code contributions from others?**
   Yes → pair any option with a CLA/DCO; B and C need clear inbound terms.
4. **How much do you care that the art may not be protectable?**
   If little, A still maximizes control. If a lot, invest in human-authored
   passes and keep provenance records before choosing an exclusive license.
5. **Mature content distribution:** confirm storefront/payment-processor rules
   and age-gating before publishing under any license.

## Minimal implementation once you choose

- **A:** `LICENSE` (all rights reserved) + `NOTICE` with the copyright line and
  third-party notices; keep the repo's default "no license" clarity.
- **B:** `LICENSE-CONTENT` (CC BY-NC 4.0, link the deed and legal code) +
  `LICENSE-CODE`, and label each asset directory with which license applies.
- **C:** `LICENSE` (source-available terms) + `CONTRIBUTING.md` with the CLA and
  a plain-language summary of what users may and may not do.

Whichever is chosen, add a short `LICENSES.md` index so users do not have to
guess which terms apply to code vs. art vs. third-party assets.
