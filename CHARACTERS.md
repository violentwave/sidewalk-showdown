# Sidewalk Showdown — Characters

**File:** `CHARACTERS.md`  
**Version:** v0.1  
**Status:** Character bible / roster design draft  
**Source Canon:** `GAME_BIBLE.md` v1.1 and `GDD.md` v0.1  
**Purpose:** Define the playable roster, Tripp Vlogs boss role, character identities, gameplay archetypes, rivalries, METHtalities, story hooks, art notes, and implementation-ready character data direction.

---

## 0. Canon Lock

These rules must not be contradicted by future character, story, art, or gameplay work.

- **Tripp Vlogs is not playable.**
- **Tripp Vlogs is the only boss.**
- **Tripp appears only as the hidden final boss at the end of story/campaign mode.**
- The current playable roster contains **15 fighters**.
- Every playable fighter has a unique **METHtality**.
- The game is Mature-rated.
- The tone is raunchy, crude, grimy, violent, chaotic, adult, and weirdly heartfelt.
- The game pokes fun at everybody.
- Nobody is clean.
- Nobody is normal.
- Nobody gets out unroasted.
- The ending is wholesome in a sideways way: the fighters remain disasters, but they come together long enough to expose Tripp.
- Character names remain as-is for now.
- The world is fictional **Sidewalk Florida**, not real Florida.
- Use no real towns, real brands, or real public figures as canon.

---

## 1. External Design Research Notes

This document uses standard fighting-game design language and archetype planning to make the roster easier to build and balance.

### 1.1 Archetype Reference

Modern fighting-game rosters commonly use readable archetypes such as:

- **Rushdown** — fast pressure, strong offense, usually weaker defense.
- **Zoner** — controls space with range, traps, projectiles, or screen denial.
- **Grappler** — scary at close range, usually slower approach, high reward on grabs.
- **Brawler / Bruiser** — straightforward power, strong normals, durable presence.
- **Wildcard / Gimmick** — unusual mechanics, randomness, traps, stance rules, or unique gimmicks.

These are used here as planning labels only. Sidewalk Showdown characters should still feel specific to the world rather than generic genre templates.

### 1.2 Accessibility Direction

The first playable implementation should favor readable character plans and accessible inputs:

```text
Neutral + Special
Forward + Special
Down + Special
Back + Special
Air + Special
```

Classic motion inputs can be tested later, but the roster should first work with simple directional specials so the prototype can focus on combat feel, hit detection, and character identity.

### 1.3 Data-Driven Character Design

Every fighter should eventually be implemented through reusable data:

```yaml
id:
display_name:
archetype:
difficulty:
home_stage:
rival_ids:
health:
walk_speed:
jump_height:
weight:
normals:
specials:
throw:
methtality:
ai_profile:
story_route:
ending_id:
```

Character concepts in this file are **design targets**, not final frame data.

---

## 2. Roster Overview

| # | Fighter | Canon Role | Gameplay Archetype | Rival(s) | Suggested Home Stage |
|---:|---|---|---|---|---|
| 1 | Peg Leg Peggy | Playable fighter | Scrappy trick fighter | Stub Stan | The Parking Lot |
| 2 | Raccoon Randy | Playable fighter | Wild rushdown / feral grappler | Garbage Gretchen | Dumpster Alley |
| 3 | Deputy Deranged | Playable fighter | Bruiser / control fighter | Stabatha Christie, Whiskey Richard | The Liquor Store |
| 4 | Lt. Dan Hurricane | Playable fighter | Tank / survivalist | Burnout Bubba | The Drainage Canal |
| 5 | Chuck Cheese Felon | Playable fighter | Chaos / gadget fighter | Dogfood Debbie | The Flea Market |
| 6 | ShroomBoom Betty | Playable fighter | Trap / confusion fighter | Python Paulie | Gas-N-Go |
| 7 | Python Paulie | Playable fighter | Grappler / constrictor fighter | ShroomBoom Betty | Under the Bridge |
| 8 | Soapless Joe | Playable fighter | Dirty speedster / evasive brawler | Hairy Mary | The Laundromat |
| 9 | Whiskey Richard | Playable fighter | Power brawler / fire gimmick | Deputy Deranged | The Alley Behind the Bar |
| 10 | Dogfood Debbie | Playable fighter | Weird zoner / bite fighter | Chuck Cheese Felon | Gas-N-Go |
| 11 | Burnout Bubba | Playable fighter | Heavy bruiser | Lt. Dan Hurricane | The Parking Lot |
| 12 | Garbage Gretchen | Playable fighter | Projectile / zoning specialist | Raccoon Randy | Dumpster Alley |
| 13 | Stub Stan | Playable fighter | Tough mid-range fighter | Peg Leg Peggy | The Bus Stop |
| 14 | Hairy Mary | Playable fighter | Grappler / intimidation fighter | Soapless Joe | The Laundromat |
| 15 | Stabatha Christie | Playable fighter | Fast assassin / slash fighter | Deputy Deranged | The Alley Behind the Bar |
| — | Tripp Vlogs | Hidden final boss only | Non-playable boss / spectacle controller | Everyone | Tripp’s Livestream Arena |

---

## 3. Global Character Design Rules

### 3.1 Every Fighter Needs Five Story Layers

Each playable fighter must have:

1. **Public Reason** — what they say they want.
2. **Private Reason** — what they actually care about.
3. **What Tripp Exploits** — the cheap angle he uses for content.
4. **What Tripp Misunderstands** — the part of them he underestimates.
5. **How They Reclaim Their Story** — how they turn his edit against him.

### 3.2 Every Fighter Needs a Gameplay Identity

Each fighter must have:

- one clear strength
- one clear weakness
- one basic gameplan
- one beginner-friendly tactic
- one advanced tactic
- one rival matchup
- one signature METHtality
- one visual silhouette rule

### 3.3 Every Fighter Should Be Funny at Three Distances

A good Sidewalk Showdown fighter should work at:

| Distance | Requirement |
|---|---|
| Far away | Instantly readable silhouette / gimmick |
| Mid-range | Clear fight style and props |
| Close-up | Funny face, dialogue, scars, accessories, expression, animation details |

### 3.4 Every Fighter Should Be Roast-Worthy and Memorable

The game pokes fun at everybody. A fighter can be gross, stupid, petty, reckless, delusional, or nasty, but they should never feel interchangeable.

The goal is:

```text
Specific disaster > generic joke
```

---

# 4. Playable Fighter Sheets

---

## 4.1 Peg Leg Peggy

**ID:** `peg_leg_peggy`  
**Role:** Playable fighter  
**Archetype:** Scrappy trick fighter  
**Difficulty:** Medium  
**Suggested Home Stage:** The Parking Lot  
**Primary Rival:** Stub Stan  
**Core Joke:** Peggy does not want sympathy. She wants receipts, revenge, and maybe a socket wrench.

### Story Layer

| Field | Direction |
|---|---|
| **Public Reason** | Wants prize money to buy back her stolen prosthetic leg from a pawn shop. |
| **Private Reason** | She wants to prove nobody gets to take pieces of her life and sell them back to her. |
| **What Tripp Exploits** | Her missing leg, her anger, and the easy “tragic fighter” angle. |
| **What Tripp Misunderstands** | Peggy is not fragile and she is not inspirational content. She is practical, stubborn, funny, and terrifyingly resourceful. |
| **How She Reclaims Her Story** | She wins her leg back, decides her homemade replacement is better anyway, and turns Tripp’s pity edit into a highlight reel of her wrecking people. |

### Gameplay Identity

Peggy should feel like an improvised-weapon trick fighter who fights dirty but intelligently. She is not the fastest character, but she has deceptive reach, awkward angles, and utility from her homemade prosthetic.

| Category | Direction |
|---|---|
| **Strengths** | Awkward hit angles, strong counter-pokes, tricky movement, good mid-range pressure |
| **Weaknesses** | Recovery on big swings, weaker air game, requires spacing awareness |
| **Beginner Tactic** | Use prosthetic pokes to keep opponents out. |
| **Advanced Tactic** | Bait approaches, then punish with counter-swing or trip setups. |

### Working Move Kit

| Move | Input Concept | Description |
|---|---|---|
| **Socket Check** | Light | Quick jab with wrench / hardware tool. |
| **Peg Sweep** | Down + Heavy | Low prosthetic sweep. |
| **Pawn Shop Poke** | Forward + Special | Extending prosthetic strike with long range. |
| **Hardware Shuffle** | Back + Special | Short evasive hop with counter-hit property. |
| **Receipt Collector** | Throw | Grabs opponent and slams them with a bag of pawn-shop junk. |

### Authored Combo Route Placeholder — Design Only

For the Phase 3 proposal, candidate data routes are `jump_heavy` (landed
starter) → `light` → `peggy_neutral`; `light` → `heavy` → `peggy_neutral`; and
`heavy` punish → `peggy_forward_ex` (with the existing EX meter cost). These
routes need frame-window and spacing validation; they do not claim every link is
currently authored or guaranteed. The shared control taxonomy applies, and
these routes must be playable on Peggy's current silhouette without animation.

### Command Grab Placeholder — Design Only

Recommended mapping: a throw-level special on **Back + Special**. This direction
currently contains **Hardware Shuffle**, so owner approval must decide whether
to replace/reclassify that row or choose another existing direction; duplicate
input/stance rows are not an acceptable implicit solution. Damage, startup,
active frames, whiff recovery, knockdown and meter gain remain to be authored.
The recommended tech policy is untechable with slower startup, pending owner
approval. Respect airborne rejection, wake-up throw invulnerability, R1
knockdown throw rejection, and the existing METHtality gate. No art or animation
is part of this placeholder.

### METHtality

**Name:** Walk the Plank  
**Concept:** Peggy knocks the opponent onto a broken board, pins them with her homemade prosthetic, and stomps them off into a cartoonish sewer/channel drop.

### Art Notes

- Homemade prosthetic should be visually iconic.
- Include toolbelt / taped hardware / scavenged metal.
- Pose should project “do not help me unless I asked.”
- Avoid pity framing; Peggy should look dangerous and confident.

### Voice / Banter

- “I don’t need a hand. I need my property back.”
- “That leg was stolen. This one was engineered.”
- “You want inspiration? Try a coupon.”

### Ending

Peggy gets her stolen prosthetic back, decides it is worse than her homemade one, and mounts it above the pawn shop counter as a warning.

---

## 4.2 Raccoon Randy

**ID:** `raccoon_randy`  
**Role:** Playable fighter  
**Archetype:** Wild rushdown / feral grappler  
**Difficulty:** Medium-High  
**Suggested Home Stage:** Dumpster Alley  
**Primary Rival:** Garbage Gretchen  
**Core Joke:** Randy may be insane, but the raccoons do appear to follow bylaws.

### Story Layer

| Field | Direction |
|---|---|
| **Public Reason** | Wants recognition for his “trash kingdom” and raccoon community. |
| **Private Reason** | He wants proof that the world he built in his head matters to somebody besides him. |
| **What Tripp Exploits** | His raccoon obsession and makes him look like a filthy lunatic animal man. |
| **What Tripp Misunderstands** | Randy understands territory, loyalty, routine, and crowd behavior better than Tripp ever will. |
| **How He Reclaims His Story** | Randy uses the raccoons and the crowd to sabotage Tripp’s production, proving his “trash kingdom” has real power. |

### Gameplay Identity

Randy should feel twitchy, fast, and hard to predict. He gets in through scrambles, pounces, and trash-based ambushes.

| Category | Direction |
|---|---|
| **Strengths** | Fast approach, strong corner pressure, weird grab routes, unpredictable movement |
| **Weaknesses** | Lower health, stubby normals, punishable if guessed correctly |
| **Beginner Tactic** | Rush in with pounce attacks and quick throws. |
| **Advanced Tactic** | Use trash decoys and feints to force panic blocking. |

### Working Move Kit

| Move | Input Concept | Description |
|---|---|---|
| **Trash Pounce** | Forward + Special | Leaping claw-style attack. |
| **Can Rattle** | Neutral + Special | Tosses a noisy can that distracts / checks movement. |
| **Dumpster Feint** | Back + Special | Quick fake-out retreat. |
| **Scavenger Scramble** | Down + Special | Low crawling rush. |
| **Territory Claim** | Throw | Randy tackles and marks the ground like he won a zoning dispute. |

### METHtality

**Name:** Trash Night  
**Concept:** A coordinated raccoon swarm drags the opponent into an overflowing trash pile while Randy solemnly declares the bylaws have been enforced.

### Art Notes

- Wild hair, trash armor, reflective raccoon eyes in background.
- Give him twitchy idle animation.
- Should look like he has not slept but has attended many imaginary council meetings.

### Voice / Banter

- “The raccoons have voted.”
- “You’re trespassing on municipal garbage.”
- “Don’t look at me. Look at the bylaws.”

### Ending

Randy declares Dumpster Alley an independent raccoon-aligned territory. The raccoons overthrow him within twenty minutes but keep him as a ceremonial figurehead.

---

## 4.3 Deputy Deranged

**ID:** `deputy_deranged`  
**Role:** Playable fighter  
**Archetype:** Bruiser / control fighter  
**Difficulty:** Medium  
**Suggested Home Stage:** The Liquor Store  
**Primary Rivals:** Stabatha Christie, Whiskey Richard  
**Core Joke:** He has no jurisdiction, but somehow still finds evidence.

### Story Layer

| Field | Direction |
|---|---|
| **Public Reason** | Enters to restore law and order to the tournament. |
| **Private Reason** | He wants people to respect him as an authority figure because nobody actually does. |
| **What Tripp Exploits** | His fake-cop energy, temper, whistle, and obsession with rules. |
| **What Tripp Misunderstands** | Deputy Deranged may be ridiculous, but he genuinely hates bullies, scams, and unfair play. |
| **How He Reclaims His Story** | He turns his fake investigation toward Tripp and accidentally helps expose the contract fraud. |

### Gameplay Identity

Deputy Deranged should control mid-range with baton pressure, command shouts, and aggressive forward movement.

| Category | Direction |
|---|---|
| **Strengths** | Strong mid-range normals, armor on some advances, good punish tools |
| **Weaknesses** | Predictable approach, vulnerable to zoning, slower recovery |
| **Beginner Tactic** | Walk down opponents with baton normals. |
| **Advanced Tactic** | Use fake command calls to bait attacks and punish. |

### Working Move Kit

| Move | Input Concept | Description |
|---|---|---|
| **Baton Citation** | Heavy | Long baton swing. |
| **Stop Right There** | Forward + Special | Armored shoulder check. |
| **Whistle Blast** | Neutral + Special | Short stun / anti-approach shout. |
| **Probable Cause** | Down + Special | Low baton sweep. |
| **Citizen’s Mistake** | Throw | Aggressive fake arrest slam. |

### METHtality

**Name:** Stop Resisting  
**Concept:** Deputy Deranged performs a wildly overdramatic fake arrest, reads the wrong rights, and slams the opponent through a folding barricade.

### Art Notes

- Suspicious badge.
- Mismatched tactical gear.
- Laminated rule cards.
- Sunglasses that look too official for someone clearly not official.

### Voice / Banter

- “I am the law-adjacent presence here.”
- “That was resisting. I decided.”
- “This whistle is department-issued by me.”

### Ending

Deputy Deranged declares the Tripp takedown “the biggest case of his career.” Nobody confirms he has a career.

---

## 4.4 Lt. Dan Hurricane

**ID:** `lt_dan_hurricane`  
**Role:** Playable fighter  
**Archetype:** Tank / survivalist  
**Difficulty:** Low-Medium  
**Suggested Home Stage:** The Drainage Canal  
**Primary Rival:** Burnout Bubba  
**Core Joke:** He is wrong about almost everything except emergency exits.

### Story Layer

| Field | Direction |
|---|---|
| **Public Reason** | Wants to fund his Hurricane Preparedness Dojo. |
| **Private Reason** | He is afraid of being powerless when disaster hits, so he built an entire identity around being ready. |
| **What Tripp Exploits** | His storm obsession, paranoia, and loud survivalist speeches. |
| **What Tripp Misunderstands** | Dan is not just a weather nut. He is brave when things actually go bad. |
| **How He Reclaims His Story** | During the final livestream collapse, Dan keeps people from getting hurt by organizing the chaos like it is a storm drill. |

### Gameplay Identity

Dan is durable, heavy, and momentum-based. He should feel like a walking storm shelter.

| Category | Direction |
|---|---|
| **Strengths** | High health, armor, strong knockdown, high damage |
| **Weaknesses** | Slow walk, weak against fast zoning, limited air mobility |
| **Beginner Tactic** | Absorb pressure and punish hard. |
| **Advanced Tactic** | Time armor moves to blow through predictable attacks. |

### Working Move Kit

| Move | Input Concept | Description |
|---|---|---|
| **Tarp Wallop** | Heavy | Heavy tarp-wrapped swing. |
| **Category Charge** | Forward + Special | Armored forward rush. |
| **Flashlight Discipline** | Neutral + Special | Blinding short-range beam. |
| **Sandbag Stomp** | Down + Special | Ground shock / low pressure. |
| **Emergency Evacuation** | Throw | Carries opponent like storm debris and dumps them. |

### METHtality

**Name:** Category 5  
**Concept:** Dan triggers a cartoon storm burst, launching the opponent through flying tarps, lawn chairs, cans, and emergency supplies.

### Art Notes

- Storm-prep gear.
- Tarp cape or sash.
- Flashlight, rope, emergency radio.
- Broad stance, heavy silhouette.

### Voice / Banter

- “I told the sky I was ready.”
- “That scooter is a weather crime.”
- “You people laughed at my tarp drills.”

### Ending

Dan opens his Hurricane Preparedness Dojo. It immediately becomes useful when Tripp’s final arena catches fire.

---

## 4.5 Chuck Cheese Felon

**ID:** `chuck_cheese_felon`  
**Role:** Playable fighter  
**Archetype:** Chaos / gadget fighter  
**Difficulty:** High  
**Suggested Home Stage:** The Flea Market  
**Primary Rival:** Dogfood Debbie  
**Core Joke:** Chuck treats arcade tokens like sacred currency.

### Story Layer

| Field | Direction |
|---|---|
| **Public Reason** | Wants to clear his name after being banned from every family arcade in the region. |
| **Private Reason** | He misses being part of a place where he felt like a champion, even if that place had sticky floors and animatronic rodents. |
| **What Tripp Exploits** | His criminal record, arcade rage, and weird grudge against mascots. |
| **What Tripp Misunderstands** | Chuck is not just a felon joke. He has rules, loyalty, and an oddly sincere sense of fair play. |
| **How He Reclaims His Story** | He exposes Tripp’s rigged arcade-style scoring system and beats him at his own cheap game. |

### Gameplay Identity

Chuck should feel unpredictable and prop-heavy, using tokens, arcade junk, broken prize machines, and mascot trauma.

| Category | Direction |
|---|---|
| **Strengths** | Setups, weird projectiles, random-looking but learnable pressure |
| **Weaknesses** | Inconsistent range, requires setup time, poor defense |
| **Beginner Tactic** | Throw arcade junk and force opponents to approach. |
| **Advanced Tactic** | Layer token traps and fake mascot pressure. |

### Working Move Kit

| Move | Input Concept | Description |
|---|---|---|
| **Token Toss** | Neutral + Special | Tosses token projectile. |
| **Prize Counter Slide** | Down + Special | Low sliding attack with stolen tickets. |
| **Mascot Trauma** | Back + Special | Summons broken mascot head as trap. |
| **Ball Pit Lunge** | Forward + Special | Chaotic leap-in attack. |
| **House Rules** | Throw | Shoves opponent into imaginary arcade cabinet. |

### METHtality

**Name:** Party Room Lock-In  
**Concept:** The opponent is trapped in a cursed birthday room while glitchy animatronic silhouettes and arcade junk overwhelm them.

### Art Notes

- Token bucket.
- Torn arcade vest / party-room aesthetic.
- Haunted family entertainment energy.
- Nervous eyes, sudden rage animation spikes.

### Voice / Banter

- “The mouse started it.”
- “Tokens are currency if you believe hard enough.”
- “I was banned unjustly from twelve locations.”

### Ending

Chuck clears his name, then gets banned from a new arcade for celebrating too hard.

---

## 4.6 ShroomBoom Betty

**ID:** `shroombom_betty`  
**Role:** Playable fighter  
**Archetype:** Trap / confusion fighter  
**Difficulty:** High  
**Suggested Home Stage:** Gas-N-Go  
**Primary Rival:** Python Paulie  
**Core Joke:** Nobody knows whether Betty’s jerky is food, medicine, or a felony.

> **Implementation Note:** The display name is **ShroomBoom Betty**. File/script ID should use `shroombom_betty` or `shroomboom_betty`; pick one canonical spelling in code before implementation. Recommended: `shroomboom_betty`.

### Story Layer

| Field | Direction |
|---|---|
| **Public Reason** | Wants money to launch her mushroom jerky business. |
| **Private Reason** | She wants people to stop treating her like a crazy roadside lady and admit she is an entrepreneur. |
| **What Tripp Exploits** | Her weird products, trippy speeches, and possible health-code violations. |
| **What Tripp Misunderstands** | Betty is strange, but she is not random. She understands chemistry, salesmanship, and intimidation. |
| **How She Reclaims Her Story** | She turns Tripp’s fake sponsor segment into a real product pitch and steals his audience. |

### Gameplay Identity

Betty should control space with spores, traps, and disorientation. She should feel like a setup character whose weirdness is strategic.

| Category | Direction |
|---|---|
| **Strengths** | Traps, delayed pressure, confusion effects, stage control |
| **Weaknesses** | Low direct damage, vulnerable when rushed, requires planning |
| **Beginner Tactic** | Place spores and force opponents to move around them. |
| **Advanced Tactic** | Layer delayed spores with fake retreat routes. |

### Working Move Kit

| Move | Input Concept | Description |
|---|---|---|
| **Spore Pop** | Neutral + Special | Slow spore projectile. |
| **Jerky Sample** | Forward + Special | Short lunge with questionable snack. |
| **Mycelium Mine** | Down + Special | Places a delayed trap. |
| **Vision Quest** | Back + Special | Creates decoy puff / retreat. |
| **Free Sample** | Throw | Forces opponent through a product demo slam. |

### METHtality

**Name:** Bad Trip  
**Concept:** The opponent hallucinates giant fungi, fake sponsor mascots, and Betty’s product labels before collapsing under a psychedelic blast.

### Art Notes

- Mushroom accessories.
- Roadside vendor / conspiracy entrepreneur look.
- Bright spores against dirty palette.
- Calm, businesslike expression despite chaos.

### Voice / Banter

- “It is not expired. It is evolving.”
- “Labels kill the mystery.”
- “You are not hallucinating. You are experiencing market disruption.”

### Ending

Betty’s mushroom jerky becomes famous after Tripp’s audience buys it ironically, then sincerely, then medically.

---

## 4.7 Python Paulie

**ID:** `python_paulie`  
**Role:** Playable fighter  
**Archetype:** Grappler / constrictor fighter  
**Difficulty:** Medium-High  
**Suggested Home Stage:** Under the Bridge  
**Primary Rival:** ShroomBoom Betty  
**Core Joke:** The snake might actually be the brains of the operation.

### Story Layer

| Field | Direction |
|---|---|
| **Public Reason** | Wants to win custody of his escaped python. |
| **Private Reason** | The python is the only thing in his life that made him feel trusted. |
| **What Tripp Exploits** | His creepy snake-guy image and emotional attachment to the python. |
| **What Tripp Misunderstands** | Paulie is not just weird. He is patient, observant, and good at reading people. |
| **How He Reclaims His Story** | Paulie helps expose Tripp by noticing hidden production cues, camera patterns, and staged “random” events. |

### Gameplay Identity

Paulie should be a patient grappler with unusual range. He threatens with constrictor grabs, but must earn his way in.

| Category | Direction |
|---|---|
| **Strengths** | Command grabs, long-range bind attacks, strong corner reward |
| **Weaknesses** | Slow start-up, weak if kept out, predictable if impatient |
| **Beginner Tactic** | Use snake-range pokes to set up grabs. |
| **Advanced Tactic** | Condition blocks with bind pressure, then command grab. |

### Working Move Kit

| Move | Input Concept | Description |
|---|---|---|
| **Snake Reach** | Heavy | Long-range python-assisted strike. |
| **Constrictor Clinch** | Forward + Special | Command grab. |
| **Cold-Blooded Read** | Back + Special | Counter stance / bait. |
| **Low Coil** | Down + Special | Low binding attack. |
| **Scale Slam** | Throw | Python-assisted toss. |

### METHtality

**Name:** Constrictor Kiss  
**Concept:** A giant python wraps the opponent, squeezes them into a dazed cartoon heap, then calmly poses for the livestream.

### Art Notes

- Python visible as scarf, shoulder wrap, or stage-assisted companion.
- Patient eyes.
- Swamp handler posture.
- Avoid making the snake too realistic/gory; keep it arcade-readable.

### Voice / Banter

- “He is not my pet. He is my legal counsel.”
- “The snake saw that coming.”
- “Do not hiss at my manager.”

### Ending

Paulie reunites with his python, only to discover the snake has become more popular than him.

---

## 4.8 Soapless Joe

**ID:** `soapless_joe`  
**Role:** Playable fighter  
**Archetype:** Dirty speedster / evasive brawler  
**Difficulty:** Medium  
**Suggested Home Stage:** The Laundromat  
**Primary Rival:** Hairy Mary  
**Core Joke:** Joe is wrong about soap but weirdly right about corporate branding.

### Story Layer

| Field | Direction |
|---|---|
| **Public Reason** | Wants to win a lifetime supply of soap so he can destroy it. |
| **Private Reason** | He wants control over his own body and refuses to be told he is disgusting by people he thinks are phonies. |
| **What Tripp Exploits** | His smell, conspiracy rants, and anti-soap philosophy. |
| **What Tripp Misunderstands** | Joe is gross, but he is not weak. He has discipline, pain tolerance, and unshakable belief. |
| **How He Reclaims His Story** | Joe weaponizes Tripp’s humiliation footage by making the crowd chant his slogan instead of laughing at him. |

### Gameplay Identity

Joe should feel slippery, gross, evasive, and surprisingly disciplined.

| Category | Direction |
|---|---|
| **Strengths** | Evasion, fast movement, slippery escapes, status-style pressure |
| **Weaknesses** | Low damage, lower health, needs repeated openings |
| **Beginner Tactic** | Dodge and poke with fast attacks. |
| **Advanced Tactic** | Use grime clouds to create ambiguous approach timing. |

### Working Move Kit

| Move | Input Concept | Description |
|---|---|---|
| **Grime Jab** | Light | Quick filthy poke. |
| **Corporate Bubble Lie** | Neutral + Special | Anti-projectile / soap rant cloud. |
| **Slip Step** | Back + Special | Evasive backslide. |
| **Rinse Cycle Rejection** | Down + Special | Low sliding attack. |
| **Personal Space Violation** | Throw | Suffocating grime clinch. |

### METHtality

**Name:** Stink Cloud  
**Concept:** Joe traps the opponent in a thick cartoon filth cloud until they stumble out defeated, spiritually changed, and possibly cleaner by comparison.

### Art Notes

- Filthy but energetic.
- Layered clothing, towel, anti-soap signs.
- Grease/slime animation trails.
- His movement should be gross but quick.

### Voice / Banter

- “Soap is obedience in bar form.”
- “You smell that? That is freedom.”
- “The laundromat fears me.”

### Ending

Joe wins the soap supply and destroys it publicly, accidentally creating the cleanest-smelling fire in county history.

---

## 4.9 Whiskey Richard

**ID:** `whiskey_richard`  
**Role:** Playable fighter  
**Archetype:** Power brawler / fire gimmick  
**Difficulty:** Low-Medium  
**Suggested Home Stage:** The Alley Behind the Bar  
**Primary Rival:** Deputy Deranged  
**Core Joke:** Richard has fallen off the same stool enough times to consider it a relationship.

### Story Layer

| Field | Direction |
|---|---|
| **Public Reason** | Wants his bar stool back. |
| **Private Reason** | The stool represents the last place where he felt respected, remembered, and part of something. |
| **What Tripp Exploits** | His anger, drinking persona, and reputation as a barfly disaster. |
| **What Tripp Misunderstands** | Richard is not just a drunk joke. He has loyalty, pride, memory, and a code. |
| **How He Reclaims His Story** | He wins back the stool, humiliates Tripp on livestream, and gives the prize speech Tripp tried to edit out. |

### Gameplay Identity

Richard is a heavy-handed brawler with volatile fire/liquor gimmicks.

| Category | Direction |
|---|---|
| **Strengths** | High damage, strong heavy attacks, scary corner pressure |
| **Weaknesses** | Slow recovery, unsafe specials, vulnerable to fast characters |
| **Beginner Tactic** | Hit hard with big normals and punish mistakes. |
| **Advanced Tactic** | Use flame threat to force jumps or bad blocks. |

### Working Move Kit

| Move | Input Concept | Description |
|---|---|---|
| **Bottle Check** | Light / Heavy | Bottle swing with different ranges. |
| **Stool Sample** | Forward + Special | Lunging bar-stool smash. |
| **Last Call Flame** | Neutral + Special | Short fire burst. |
| **Bar Mat Slide** | Down + Special | Low sliding shove. |
| **Karaoke Regret** | Throw | Slams opponent like a failed performance. |

### Authored Combo Route Placeholder — Design Only

For the Phase 3 proposal, candidate data routes are `jump_heavy` (landed
starter) → `light` → `richard_neutral`; `light` → `heavy` → `richard_forward`;
and `heavy` punish → `richard_forward_ex` (with the existing EX meter cost).
These routes need frame-window and spacing validation; they do not claim every
link is currently authored or guaranteed. The shared control taxonomy applies,
and these routes must be playable on Richard's current silhouette without
animation.

### Command Grab Placeholder — Design Only

Recommended mapping: a throw-level special on **Forward + Special**. This
direction currently contains **Stool Sample**, so owner approval must decide
whether to replace/reclassify that row or choose another existing direction;
duplicate input/stance rows are not an acceptable implicit solution. Damage,
startup, active frames, whiff recovery, knockdown and meter gain remain to be
authored. The recommended tech policy is untechable with slower startup, pending
owner approval. Respect airborne rejection, wake-up throw invulnerability, R1
knockdown throw rejection, and the existing METHtality gate. No art or animation
is part of this placeholder.

### METHtality

**Name:** Flaming Belch  
**Concept:** Richard drenches the scene in cartoon whiskey fumes, lets out an absurd fire belch, and launches the opponent through a bar sign.

### Art Notes

- Barfly silhouette.
- Bottle/stool prop.
- Warm fire palette.
- Should be pathetic and powerful at the same time.

### Voice / Banter

- “That stool knows my name.”
- “I was not removed. I was retired.”
- “Nobody bans the song but me.”

### Ending

Richard gets his bar stool back, gives a surprisingly moving speech, then falls off the stool during applause.

---

## 4.10 Dogfood Debbie

**ID:** `dogfood_debbie`  
**Role:** Playable fighter  
**Archetype:** Weird zoner / bite fighter  
**Difficulty:** Medium  
**Suggested Home Stage:** Gas-N-Go  
**Primary Rival:** Chuck Cheese Felon  
**Core Joke:** Nobody can prove her food is illegal, and that seems to bother everyone.

### Story Layer

| Field | Direction |
|---|---|
| **Public Reason** | Wants to fund her gourmet dog food truck. |
| **Private Reason** | She wants to prove her disgusting business idea is not disgusting if people would stop asking questions. |
| **What Tripp Exploits** | Her food, her hygiene, and the horrifying ambiguity of her menu. |
| **What Tripp Misunderstands** | Debbie knows exactly how gross her brand is. That is the brand. |
| **How She Reclaims Her Story** | Debbie turns Tripp’s mockery into viral demand and gets customers lined up around the block. |

### Gameplay Identity

Debbie controls space with food tosses, bite lunges, and stray-dog chaos.

| Category | Direction |
|---|---|
| **Strengths** | Projectiles, weird angles, strong anti-air, good chip pressure |
| **Weaknesses** | Slow movement, limited close defense, odd timing |
| **Beginner Tactic** | Throw food to control approach. |
| **Advanced Tactic** | Use bait-food setups to force bad jumps. |

### Working Move Kit

| Move | Input Concept | Description |
|---|---|---|
| **Mystery Meat Toss** | Neutral + Special | Tosses questionable food projectile. |
| **Bowl Bash** | Heavy | Heavy swing with serving bowl. |
| **Heel Bite** | Down + Special | Low bite/lunge attack. |
| **Food Truck Rush** | Forward + Special | Shoulder charge with menu board. |
| **No Refunds** | Throw | Smashes opponent with food-service tray. |

### METHtality

**Name:** Dinner Time  
**Concept:** Debbie rings a nasty dinner bell and a pack of cartoon strays swarms the opponent while she explains her business plan.

### Art Notes

- Apron / food truck vendor vibe.
- Dog bowl, ladle, mystery cans.
- Expression should be intense and proud.
- Gross but entrepreneurial.

### Voice / Banter

- “It is food if you chew it.”
- “My customers do not ask questions.”
- “That bucket was repurposed legally.”

### Ending

Debbie’s food truck becomes a hit because nobody can prove it is not food.

---

## 4.11 Burnout Bubba

**ID:** `burnout_bubba`  
**Role:** Playable fighter  
**Archetype:** Heavy bruiser  
**Difficulty:** Low  
**Suggested Home Stage:** The Parking Lot  
**Primary Rival:** Lt. Dan Hurricane  
**Core Joke:** Bubba insists it is not a scooter. It is “a two-wheeled custody agreement.”

### Story Layer

| Field | Direction |
|---|---|
| **Public Reason** | Wants to rebuild his scooter, The Divorce Horse. |
| **Private Reason** | The scooter is the last thing in his life that never judged him, left him, or asked him to grow up. |
| **What Tripp Exploits** | His burnout image, failed relationships, and pathetic scooter pride. |
| **What Tripp Misunderstands** | Bubba may be a mess, but he is fearless, mechanically clever, and weirdly loyal. |
| **How He Reclaims His Story** | Bubba uses The Divorce Horse to crash Tripp’s finale and turn the arena into a demolition derby. |

### Gameplay Identity

Bubba is the beginner-friendly heavy bruiser: slow, direct, durable, and satisfying.

| Category | Direction |
|---|---|
| **Strengths** | Big damage, simple gameplan, high health, strong knockdowns |
| **Weaknesses** | Slow movement, weak against keepaway, predictable |
| **Beginner Tactic** | Walk forward, block, punish with heavy hits. |
| **Advanced Tactic** | Use delayed armor and scooter feints to catch panic buttons. |

### Working Move Kit

| Move | Input Concept | Description |
|---|---|---|
| **Gas Station Uppercut** | Forward + Special | Big rising punch. |
| **Divorce Horse Rev** | Neutral + Special | Short scooter-part charge / armor startup. |
| **Oil Spill Stomp** | Down + Special | Ground control low stomp. |
| **Backroad Haymaker** | Heavy | Slow, high-damage punch. |
| **Custody Toss** | Throw | Grabs opponent and slams them like luggage. |

### METHtality

**Name:** Road Rash  
**Concept:** Bubba clotheslines the opponent onto hot pavement, revs The Divorce Horse, and drags them through a flaming trail of busted scooter parts.

### Art Notes

- Scooter patches, grease stains, busted helmet.
- Strong round silhouette.
- Mechanics tools and burnout posture.
- Funny but physically imposing.

### Voice / Banter

- “It ain’t a scooter.”
- “The Divorce Horse rides again.”
- “I got three payments left and no fear.”

### Ending

Bubba rebuilds The Divorce Horse and rides it through Tripp’s apology video set.

---

## 4.12 Garbage Gretchen

**ID:** `garbage_gretchen`  
**Role:** Playable fighter  
**Archetype:** Projectile / zoning specialist  
**Difficulty:** Medium  
**Suggested Home Stage:** Dumpster Alley  
**Primary Rival:** Raccoon Randy  
**Core Joke:** Gretchen calls it garbage. Everyone else calls it evidence.

### Story Layer

| Field | Direction |
|---|---|
| **Public Reason** | Wants to defend her title as queen of Dumpster Alley. |
| **Private Reason** | Dumpster Alley is the only kingdom where nobody got to tell her she did not belong. |
| **What Tripp Exploits** | Her trash queen image, aggression, and filthy local legend status. |
| **What Tripp Misunderstands** | Gretchen has community, territory, alliances, and more influence than his stream. |
| **How She Reclaims Her Story** | She rallies Dumpster Alley, shuts down Tripp’s merch theft, and charges him rent for using her image. |

### Gameplay Identity

Gretchen is a classic zoner with trash projectiles, space control, and defensive setups.

| Category | Direction |
|---|---|
| **Strengths** | Projectiles, anti-approach tools, corner traps, strong screen control |
| **Weaknesses** | Weak close-range defense, slow recovery, vulnerable if cornered |
| **Beginner Tactic** | Throw junk and make opponents fight through it. |
| **Advanced Tactic** | Layer trash arcs to cover multiple approach angles. |

### Working Move Kit

| Move | Input Concept | Description |
|---|---|---|
| **Can Pitch** | Neutral + Special | Fast straight projectile. |
| **Bag Arc** | Back + Special | Lobbed trash bag projectile. |
| **Rat Line** | Down + Special | Ground-based moving hazard. |
| **Dumpster Lid** | Heavy | Big shield-like swing. |
| **Eviction Notice** | Throw | Throws opponent into imaginary dumpster territory. |

### METHtality

**Name:** Dumpster Dive  
**Concept:** Gretchen knocks the opponent into a dumpster, slams the lid, crowns herself, and somehow compact-crushes the whole thing with royal authority.

### Art Notes

- Trash crown / improvised royal elements.
- Layered junk accessories.
- Strong defensive stance.
- Raccoons in stage can react to her.

### Voice / Banter

- “That is not trash. That is inventory.”
- “You owe rent to the alley.”
- “Randy, your raccoons are temps.”

### Ending

Gretchen wins royalties from Tripp’s bootleg merch and uses the money to upgrade Dumpster Alley with a throne.

---

## 4.13 Stub Stan

**ID:** `stub_stan`  
**Role:** Playable fighter  
**Archetype:** Tough mid-range fighter  
**Difficulty:** Medium  
**Suggested Home Stage:** The Bus Stop  
**Primary Rival:** Peg Leg Peggy  
**Core Joke:** Stan thinks three toes should be enough for a legacy brand.

### Story Layer

| Field | Direction |
|---|---|
| **Public Reason** | Wants naming rights to the bench where he lost three toes. |
| **Private Reason** | He wants proof that his life left a mark somewhere, even if that mark is a plaque on a terrible bench. |
| **What Tripp Exploits** | His injury, bitterness, and obsession with being remembered. |
| **What Tripp Misunderstands** | Stan is not just a sad old injury story. He is stubborn, funny, and impossible to shame. |
| **How He Reclaims His Story** | Stan gets the bench renamed on his own terms and makes Tripp read the dedication after losing. |

### Gameplay Identity

Stan is compact, stubborn, and hard to move. He should feel like a low-center-of-gravity mid-range fighter.

| Category | Direction |
|---|---|
| **Strengths** | Strong grounded normals, hard knockdowns, good anti-air |
| **Weaknesses** | Shorter range, weaker jump game, can struggle against zoning |
| **Beginner Tactic** | Stay grounded and punish jumps. |
| **Advanced Tactic** | Use stubby low-profile movement to slip under high attacks. |

### Working Move Kit

| Move | Input Concept | Description |
|---|---|---|
| **Bench Claim** | Heavy | Heavy forward swing. |
| **Toe Tax** | Down + Special | Low strike / trip. |
| **Plaque Attack** | Neutral + Special | Tosses dedication plaque. |
| **Six Inches Left** | Back + Special | Low-profile reposition. |
| **Legacy Slam** | Throw | Throws opponent onto sacred bench marker. |

### METHtality

**Name:** Short Fuse  
**Concept:** Stan lights a tiny, petty explosive near the historical bench plaque, launching the opponent into a commemorative sign.

### Art Notes

- Compact body shape.
- Bitter facial expression.
- Bench/plaque visual motifs.
- Movement should feel stubborn, not helpless.

### Voice / Banter

- “That bench knows what happened.”
- “Three toes is a legacy.”
- “Peggy gets hardware. I get history.”

### Ending

Stan gets his bench plaque. His name is spelled wrong. He immediately begins a sequel feud.

---

## 4.14 Hairy Mary

**ID:** `hairy_mary`  
**Role:** Playable fighter  
**Archetype:** Grappler / intimidation fighter  
**Difficulty:** Medium  
**Suggested Home Stage:** The Laundromat  
**Primary Rival:** Soapless Joe  
**Core Joke:** Mary believes every man is one wax strip away from accountability.

### Story Layer

| Field | Direction |
|---|---|
| **Public Reason** | Wants money to fund her mobile waxing-and-revenge business. |
| **Private Reason** | She wants control, respect, and the right to make people fear a folding salon chair. |
| **What Tripp Exploits** | Her appearance, aggression, body-hair jokes, and threatening beauty-business energy. |
| **What Tripp Misunderstands** | Mary is not embarrassed by being gross, hairy, loud, or intimidating. She built a business model out of it. |
| **How She Reclaims Her Story** | Mary turns Tripp’s mockery into marketing and leaves his final boss arena looking like a botched spa crime scene. |

### Gameplay Identity

Mary is a close-range grappler with terrifying command grabs and intimidation pressure.

| Category | Direction |
|---|---|
| **Strengths** | Command grabs, high close-range damage, strong mental pressure |
| **Weaknesses** | Slow approach, vulnerable to zoning, needs close range |
| **Beginner Tactic** | Walk opponents to the corner and grab. |
| **Advanced Tactic** | Condition jumps with anti-air, then force grab mixups. |

### Working Move Kit

| Move | Input Concept | Description |
|---|---|---|
| **Salon Chair Slam** | Forward + Special | Advancing grab attempt. |
| **Wax Strip Warning** | Neutral + Special | Threatening mid-range swipe. |
| **No Appointment Needed** | Down + Special | Low grab / trip. |
| **Follicle Fury** | Heavy | Big clawing swing. |
| **Consultation Fee** | Throw | Command-grab style toss. |

### METHtality

**Name:** Bear Hug from Hell  
**Concept:** Mary crushes the opponent in a monstrous hug, whips out salon gear, and turns the finish into a terrifying mobile-spa incident.

### Art Notes

- Big silhouette.
- Folding salon chair / waxing kit.
- Hairy, intimidating, unapologetic.
- She should look like a business owner and a threat.

### Voice / Banter

- “You are overdue.”
- “Every grudge needs aftercare.”
- “Joe, I am your destiny.”

### Ending

Mary turns Tripp’s humiliation footage into an ad for her mobile waxing business.

---

## 4.15 Stabatha Christie

**ID:** `stabatha_christie`  
**Role:** Playable fighter  
**Archetype:** Fast assassin / slash fighter  
**Difficulty:** High  
**Suggested Home Stage:** The Alley Behind the Bar  
**Primary Rival:** Deputy Deranged  
**Core Joke:** There was no murder, but somehow she still finds the culprit.

### Story Layer

| Field | Direction |
|---|---|
| **Public Reason** | Enters because she believes the tournament is secretly a murder mystery. |
| **Private Reason** | She wants to prove she is the smartest person in any room, alley, or crime scene she invents. |
| **What Tripp Exploits** | Her paranoia, knife-themed persona, and obsession with clues. |
| **What Tripp Misunderstands** | Stabatha may be wrong about the murder, but she is right that something criminal is happening. |
| **How She Reclaims Her Story** | She accidentally solves the real mystery: Tripp’s scam. Then she takes full credit for knowing it all along. |

### Gameplay Identity

Stabatha is fast, slippery, and precise. She thrives on whiff punishes, movement tricks, and “case file” setups.

| Category | Direction |
|---|---|
| **Strengths** | Speed, whiff punishes, strong air-to-ground attacks, tricky movement |
| **Weaknesses** | Low health, lower damage without setups, punishable specials |
| **Beginner Tactic** | Dash in and out to bait whiffs. |
| **Advanced Tactic** | Use clue markers / feints to create punish windows. |

### Working Move Kit

| Move | Input Concept | Description |
|---|---|---|
| **Clue Slash** | Light / Heavy | Fast knife-themed slash. |
| **Red Herring** | Back + Special | Feint / fake retreat. |
| **Evidence Plant** | Down + Special | Places a clue marker / trap. |
| **Plot Twist Lunge** | Forward + Special | Fast forward stab. |
| **Interrogation Point** | Throw | Pins opponent and accuses them mid-slam. |

### METHtality

**Name:** Case Closed  
**Concept:** Stabatha outlines the opponent in chalk, rapidly “solves” the wrong crime, lands a dramatic slash sequence, and stamps the file closed.

### Art Notes

- Mystery/detective parody plus slasher energy.
- Knife motif, case notes, chalk, trench-coat or improvised detective pieces.
- Movement should be theatrical and sharp.

### Voice / Banter

- “The motive was obvious once I invented it.”
- “Nobody move. Especially you.”
- “There was no murder. Yet.”

### Ending

Stabatha declares she solved the case. There was no murder, but Tripp confesses to several crimes by accident.

---

# 5. Non-Playable Boss

---

## 5.1 Tripp Vlogs

**ID:** `tripp_vlogs`  
**Role:** Hidden final boss only  
**Playable:** No  
**Selectable:** No  
**Boss Count:** Tripp is the only boss in story/campaign mode  
**Stage:** Tripp’s Livestream Arena  
**Core Joke:** A parasite with a ring light who thinks attention makes him superior.

### Canon Function

Tripp creates Sidewalk Showdown after accidentally filming a viral bus stop fight. He rigs the bracket, manipulates contestants, lies about the prize, and turns everyone’s worst personality trait into a monetized clip.

After the player wins the tournament, Tripp refuses to pay. He reveals a hidden commissioner clause and forces the final fight in his livestream arena.

### Boss Gameplay Identity

Tripp should not fight like a trained fighter. He should fight like a scammer with equipment.

| Category | Direction |
|---|---|
| **Strengths** | Stage control, drones, stuns, projectile clutter, phase changes |
| **Weaknesses** | Fragile when cornered, punishable panic moves, overcommits to spectacle |
| **Boss Feel** | Cheap, flashy, annoying, readable, beatable |
| **Player Emotion Goal** | “I hate this guy and I cannot wait to hit him.” |

### Boss Move Kit

| Move | Description |
|---|---|
| **Selfie Stick Sweep** | Long-range staff-like strike. |
| **Ring Light Flash** | Blinds/stuns the player briefly after clear startup. |
| **Drone Drop** | Drones crash into marked zones. |
| **Comment Section Barrage** | Toxic chat messages become projectile clutter. |
| **Sponsor Chug** | Drinks a shady energy drink for temporary speed. |
| **Apology Armor** | Fake-cries to gain temporary defense. |
| **Thumbnail Trap** | Giant red arrows and captions clutter the screen. |
| **Algorithm Shift** | Arena hazards change at health thresholds. |
| **Cancel Panic** | Final phase where he attacks faster as the follower count drops. |

### Boss Phases

| Phase | Health Range | Behavior |
|---|---:|---|
| **Phase 1: Fake Professional** | 100%–70% | Uses selfie stick, ring light, sponsor chug. |
| **Phase 2: Algorithm Boost** | 70%–35% | Adds drones, comment projectiles, thumbnail traps. |
| **Phase 3: Cancel Panic** | 35%–0% | Faster, sloppier, more desperate. Subscriber counter glitches downward. |

### Defeat / Downfall

After Tripp loses:

- the stream stays live
- raw footage leaks
- sponsors vanish
- the chat turns on him
- his apology video auto-uploads while he is still insulting everyone
- every fighter becomes more famous than him
- Tripp survives, but his brand dies

### Boss Art Notes

- Fake tactical influencer gear.
- Reinforced selfie stick.
- Ring lights, drone controller, sponsor patches.
- Expression should shift from smug to terrified.
- Should look expensive and pathetic at the same time.

### Boss Voice Lines

- “I made you people.”
- “You were yelling at traffic before I gave you lower-thirds.”
- “Do not listen to the contestants. They are emotional and contractually mine.”
- “This is not exploitation. This is vertical-format hope.”
- “Why is the subscriber count going down?”

---

# 6. Rivalry Matrix

| Rivalry | Conflict Engine | Gameplay Purpose |
|---|---|---|
| Peg Leg Peggy vs. Stub Stan | Competing injury-legacies and branding resentment | Scrappy range vs compact mid-range |
| Raccoon Randy vs. Garbage Gretchen | Raccoon liberation vs raccoon labor control | Rushdown vs zoning |
| Deputy Deranged vs. Stabatha Christie | Fake law enforcement vs fake detective genius | Bruiser control vs evasive assassin |
| Lt. Dan Hurricane vs. Burnout Bubba | Storm survivalist vs scooter burnout | Tank vs heavy bruiser |
| Chuck Cheese Felon vs. Dogfood Debbie | Token bucket dispute and cursed food-service logic | Gadget chaos vs weird zoning |
| ShroomBoom Betty vs. Python Paulie | Mushroom products made the python “too aware” | Trap setup vs grappler pressure |
| Soapless Joe vs. Hairy Mary | Anti-soap philosophy vs waxing-and-revenge business | Speedster evasion vs command grabs |
| Whiskey Richard vs. Deputy Deranged | Bar incidents and fake authority | Power brawler vs control bruiser |
| Everyone vs. Tripp | Exploited fighters expose the scammer | Campaign emotional turn |

---

# 7. Character Data Template

Use this template when splitting characters into individual files later.

```yaml
id:
display_name:
role: playable
archetype:
difficulty:
home_stage:
rival_ids: []
health:
walk_speed:
back_walk_speed:
jump_height:
dash_distance:
weight:
meter_gain_modifier:
strengths: []
weaknesses: []
public_reason:
private_reason:
tripp_exploits:
tripp_misunderstands:
reclaim_story:
moves:
  normals:
    light:
    heavy:
    crouch_light:
    crouch_heavy:
    jump_light:
    jump_heavy:
  specials:
    neutral_special:
    forward_special:
    down_special:
    back_special:
    air_special:
  throw:
  methtality:
voice:
  intro_lines: []
  win_lines: []
  loss_lines: []
  rival_lines: []
art:
  silhouette:
  palette:
  props:
  animation_notes:
audio:
  voice_style:
  sfx_motifs:
ai:
  gameplan:
  aggression:
  defensive_behavior:
story:
  intro_scene:
  rival_scene:
  tripp_manipulation_scene:
  ending:
```

---

# 8. Initial Balance Spread

This spread is not final. It exists to keep the roster from collapsing into fifteen similar brawlers.

| Fighter | Power | Speed | Range | Defense | Complexity |
|---|---:|---:|---:|---:|---:|
| Peg Leg Peggy | 3 | 3 | 4 | 3 | 3 |
| Raccoon Randy | 3 | 5 | 2 | 2 | 4 |
| Deputy Deranged | 4 | 3 | 3 | 4 | 3 |
| Lt. Dan Hurricane | 5 | 1 | 3 | 5 | 2 |
| Chuck Cheese Felon | 3 | 3 | 4 | 2 | 5 |
| ShroomBoom Betty | 2 | 2 | 5 | 2 | 5 |
| Python Paulie | 4 | 2 | 4 | 3 | 4 |
| Soapless Joe | 2 | 5 | 2 | 2 | 3 |
| Whiskey Richard | 5 | 2 | 3 | 3 | 2 |
| Dogfood Debbie | 3 | 2 | 5 | 3 | 3 |
| Burnout Bubba | 5 | 2 | 2 | 4 | 1 |
| Garbage Gretchen | 3 | 2 | 5 | 3 | 3 |
| Stub Stan | 4 | 3 | 3 | 4 | 3 |
| Hairy Mary | 5 | 1 | 2 | 5 | 3 |
| Stabatha Christie | 3 | 5 | 3 | 1 | 5 |

Scale: `1 = low`, `5 = high`.

---

# 9. Prototype Priority Recommendation

For the first playable prototype, use:

## Fighter 1: Burnout Bubba

Reasons:

- simple heavy bruiser
- readable moves
- beginner-friendly
- strong personality
- good test case for knockback and hitstop

## Fighter 2: Peg Leg Peggy or Raccoon Randy

### Peg Leg Peggy

Best for testing:

- mid-range tricks
- limb/prosthetic reach
- counter-pokes
- grounded spacing

### Raccoon Randy

Best for testing:

- rushdown
- fast approach
- chaotic animation
- close-range pressure

## Recommended First Pair

```text
Burnout Bubba vs. Peg Leg Peggy
```

This gives the prototype a clean contrast:

```text
slow heavy bruiser
vs.
scrappy mid-range trick fighter
```

Then add Raccoon Randy third to test speed and chaos.

---

# 10. AI Assistant Guardrails for Character Work

When asking AI tools to create, revise, draw, animate, or code characters, include these rules:

- Do not make Tripp playable.
- Do not add new bosses.
- Do not rename characters without explicit approval.
- Do not sanitize the Mature tone.
- Do not remove METHtalities.
- Do not turn the game into a realistic social drama.
- Do not make characters generic superheroes, martial artists, or fantasy warriors.
- Keep characters grounded in Sidewalk Florida absurdity.
- Every character must have a flaw, a joke, a grudge, and a reason to fight.
- Every character must be funny from silhouette, dialogue, and moveset.
- Every character must be playable as an arcade fighter, not just a joke concept.
- Every METHtality must be character-specific.
- Tripp is the only final boss and should appear only at the end of campaign/story mode.

---

# 11. Open Character Questions

These should be answered later during move-design and art-design passes.

1. Which fighter is the default/tutorial character?
2. Does every fighter get one METHtality or multiple variants?
3. Should METHtalities require unique inputs per fighter or one universal input?
4. Which characters should be easiest for new players?
5. Should every fighter have a home stage, or should some share stages?
6. Should rival fights include unique intros and mid-fight callouts?
7. Should any character have a non-combat cameo in another fighter’s ending?
8. Should Tripp have one METHtality-style boss finisher, or should he be denied that system because he is not a real fighter?
9. Should there be alternate palettes based on fake sponsors?
10. Should every character have a “Tripp edit” portrait and a “true self” portrait?

---

# 12. Final Character Direction

The roster should feel like a parking-lot mythological pantheon.

Every fighter should be:

- absurd
- specific
- roast-worthy
- dangerous
- funny
- visually readable
- mechanically distinct
- emotionally petty
- strangely proud

The characters are not noble heroes.

They are not clean victims.

They are not generic criminals.

They are not realistic case studies.

They are arcade legends with bad judgment.

Tripp thinks they are disposable content.

The game proves they are the whole show.
