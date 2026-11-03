# Sidewalk Showdown --- Conversation Archive & Project History

**Archive generated:** 2026-11-03\
**Project:** Sidewalk Showdown\
**Archive type:** Recovered conversation + reconstructed project
history\
**Primary source files:** `GAME_BIBLE.md`, `GDD.md`, `CHARACTERS.md`,
`STAGES.md`, `CAMPAIGN_STRUCTURE.md`, `ART_DIRECTION.md`,
`AI_WORKFLOW.md`, `CURRENT_STATE.md`, `ROADMAP.md`, `TASKS.md`, and
phase closeout reports.

------------------------------------------------------------------------

## Important note about transcript accuracy

This file is intended to preserve the Sidewalk Showdown discussion and
project decisions in one portable Markdown document.

It is **not a complete verbatim export of every ChatGPT message**. The
conversation context available for this archive contains a number of the
user's original prompts, project files, and summaries of prior work, but
some earlier assistant turns are omitted from the recoverable history.
ChatGPT does not provide me with a way to retrieve those omitted turns
word-for-word.

To avoid inventing dialogue:

-   User messages reproduced in the **Recovered user-message
    transcript** are preserved from the available conversation context,
    including original spelling and wording where available.
-   Assistant-side descriptions are clearly labeled as **reconstructed
    summaries**, not quotations.
-   Project facts and implementation status are taken from the surviving
    project documents.
-   Where two surviving records appear to disagree or where a later
    state is not confirmed by the uploaded files, the discrepancy is
    called out instead of silently choosing one version.

For a truly complete, word-for-word transcript, the missing original
conversation turns would need to be supplied through a ChatGPT
conversation export. This archive is the most detailed reconstruction
supported by the material currently available.

------------------------------------------------------------------------

# 1. Project at a glance

**Sidewalk Showdown** is a Mature-rated, retro 2D arcade fighting game
inspired by classic fighting games such as *Street Fighter*, with an
8-bit / 16-bit-inspired pixel-art presentation.

It takes place in **Sidewalk Florida**: a fictional, exaggerated
Florida-style world made up of bus stops, liquor stores, parking lots,
drainage canals, laundromats, flea markets, gas stations, alleys,
dumpsters, and other local battlegrounds.

The tournament is created by **Tripp Vlogs**, a washed-up livestreamer
who accidentally captures a sidewalk fight at a bus stop. The clip goes
viral, giving Tripp a chance to revive his failing channel. He turns the
incident into a livestreamed, winner-takes-all fighting tournament and
sells it as a life-changing opportunity.

Tripp does not genuinely want to help the fighters. He looks down on
them, sees them as disposable content, and believes his online attention
makes him superior. He rigs the tournament, manipulates the contestants,
exploits their personal stories, and tries to monetize their
humiliation.

The playable fighters eventually realize they are being manipulated. The
tournament winner expects the promised prize, but Tripp refuses to pay
and reveals a hidden final-boss condition. Tripp becomes the one and
only boss, fought at the end of story/campaign mode in **Tripp's
Livestream Arena**.

The ending is triumphant and weirdly wholesome without turning the cast
into respectable heroes. The fighters expose Tripp, reclaim their
stories, and ruin his livestream empire. They remain flawed, petty,
ridiculous people --- just a little more loyal to one another.

## Core locked facts

-   The game is a Mature-rated adult comedy fighter.
-   The setting is fictional Sidewalk Florida, not a real Florida town
    or a real-world location.
-   The current playable roster has 15 fighters.
-   Tripp Vlogs is not playable.
-   Tripp Vlogs is the only boss.
-   Tripp is the hidden final boss at the end of story/campaign mode.
-   Every playable fighter has a unique METHtality.
-   The term **METHtality** is intentionally retained.
-   Character names remain unchanged unless the user later approves
    revisions.
-   The comedy pokes fun at everybody.
-   The ending must remain weirdly wholesome.
-   No real towns, real brands, or real public figures should become
    canon.
-   Stages are recognizable place-types, not named real towns.

------------------------------------------------------------------------

# 2. Recovered user-message transcript

The following messages are reproduced from the conversation history that
remains available. Timestamps are included where they were available in
the recovered context. Some messages were sent with images or
attachments; those attachments are noted.

## 2026-05-30 --- Initial project recall and planning

### 21:47:40 UTC --- User

> Do you remember a project we were working on called sidewalk showdown
> it was a video game similar to street fighter and an eight bit style
> you helped me design a lot of the mock up images and the storyline

**Reconstructed assistant-side outcome:** The project was recognized as
the retro fighting-game concept Sidewalk Showdown. The surviving project
material confirms the Street Fighter-like 2D fighter direction, retro
pixel-art style, Florida-inspired setting, ensemble roster, and Tripp
Vlogs tournament premise.

### 21:48:38 UTC --- User

> What's a free open source version of godot I could use?

**Reconstructed assistant-side outcome:** The discussion concerned using
Godot as the free, open-source game engine. The project later
standardized on Godot 4.x. The uploaded production snapshot identifies
Godot 4.6.3 stable, installed through Flatpak, as the engine used for
the prototype.

### 21:50:24 UTC --- User

> How should I get started with the storyline or creating the final
> artwork for characters and levels? What do you recommend my main goal
> is to get everything extremely organized and easy for me and AI
> assistance to work on.

**Reconstructed assistant-side outcome:** The core recommendation was to
establish a structured source of truth before scaling content. Story
canon, game design, character design, stages, art direction, production
tasks, and AI workflow guidance should live in separate, clearly named
documents. The project should distinguish approved canon from proposals
and experiments so AI tools and human contributors do not accidentally
overwrite decisions.

### 21:52:46 UTC --- User

> Is this phase plan you came up with how an experienced solo game
> developer would accomplish it?

**Reconstructed assistant-side outcome:** The production approach was
reviewed against a professional solo-development workflow: first
organize the source of truth, then prove the core combat loop with a
greybox prototype, create a small vertical slice, build reusable
systems, lock the visual direction, and only then expand the roster,
stages, campaign, and polish. The important principle was to avoid
producing the entire final roster and all final art before proving that
the core fighting game works.

### 21:56:45 UTC --- User

> can you recall word for word the exact storyline? it was something
> along the lines of a youtuber named Tripp Vlogs pays floridian street
> bums to fight eachother in a brackted contest, winner takes all.
>
> give me the exact storyline if you can find it

**Reconstructed assistant-side outcome:** The surviving story materials
establish the central premise: Tripp Vlogs captures a fight at a bus
stop, realizes the footage can revive his failing channel, and creates a
winner-takes-all livestream tournament using local Sidewalk Florida
personalities. The exact original wording of the earliest story
conversation is not recoverable from the current context, so this
archive does not present reconstructed prose as a verbatim original.

### 22:03:34 UTC --- User

> Based on the information i gave you and anytihng you can find in your
> memory of the game, create a rough 'bible' for us to get started.

**Reconstructed assistant-side outcome:** A preliminary game/story bible
was developed as the foundation for the setting, premise, antagonist,
roster, stages, humor, and campaign. It was then revised as the user
supplied more specific stage and roster requirements.

### 22:15:42 UTC --- User

> the rough plan looks good but let's change the stages you came up
> with, i don't want specific towns as stages, they need to be places
> like 'the bus stop', 'the liquor store', 'under a bridge' etc.(i
> attached two example levels with a rough art style as well)
>
> 2.  all characters will have their own special moves called
>     METHtalities(or something similar/funny)
>
> 3.  here is the full current list of characters: Tripp Vlogs(the
>     antagonist the entire game), Peg Leg Peggy, Racoon Randy, Deputy
>     Deranged, Lt. Dan Hurricane, Chuck Cheese Felon, ShroomBoom Betty,
>     Python Paulie, Soapless Joe, Whiskey Richard, Dogfood Debbie,
>     Burnout Bubba, Garbage Gretchen, Stub Stan, Hairy Mary, and
>     Stabatha Christie.
>
> Give me the full revised bible, make sure theres nothing else missing
> that's vital to the plot

**Reconstructed assistant-side outcome:** The stage concept was changed
from specific towns to recognizable local places, such as The Bus Stop,
The Liquor Store, and Under the Bridge. The METHtality name was
introduced as the unique finisher concept for every playable fighter.
The 15-character roster was established, with Tripp included as the
antagonist rather than a normal roster fighter. The user also supplied
two rough level-art references.

### 22:27:03 UTC --- User

> before we turn it into a offical GDD format, let's use a writing gpt
> to review the story's game bible, and make additions/revisions to make
> the story more captivating, ensure it sounds human written and be
> extremely captivating/action packed. Draw inspiration from humor
> similar to the tv shows 'It's always sunny in philadelphia' and 'what
> we do in the shadows'

**Reconstructed assistant-side outcome:** The story was sent through a
more ambitious editorial direction: stronger character motivations,
sharper ensemble comedy, action escalation, more distinctive rivalries,
a clearer antagonist arc, and an ending with emotional payoff. The
requested tonal references were *It's Always Sunny in Philadelphia* and
*What We Do in the Shadows*. The goal was inspiration from their style
of character-driven, self-important, chaotic comedy, not copying their
dialogue or plots.

### 22:41:40 UTC --- User

> here was the output of the story, review it's contents and make sure
> it all makes sense before creating our GDD and reviesed Gamebible
> files:

**Reconstructed assistant-side outcome:** Two revised story-bible drafts
survive among the uploaded materials as `Pasted markdown.md` and
`Pasted markdown(1).md`. One specifically clarifies that Tripp looks
down on the fighters rather than secretly envying them. The later
revised draft includes the user's subsequent canon corrections. These
pasted drafts are source materials, not complete chat transcripts.

### 22:58:35 UTC --- User

> 1.  tripp is not a playable character, he is the main antagonist
>     /hidden boss at the end of the story/tournament. He is the only
>     'boss' in the game, at the end of the story/campaign mode.
>
> 2.  Leave the names as is for now, i will decide if they need to be
>     changed later so that it is 100% legal under parody laws.
>
> 3.  leave METHtalities as it is. The game is going to have a rating of
>     mature so it can touch on these subjects and have the raunchy
>     adult humor.
>
> 4.  do not change the moral direction of my game. it is meant to poke
>     fun at EVERYBODY while having a wholesome ending.
>
> 5.  attached is the reviesed game bible with all of the mentioned
>     changes:

**Reconstructed assistant-side outcome:** These instructions became the
central canon lock. Tripp is not playable, is the only boss, and appears
as the hidden final boss only at the end of campaign mode. Names were to
remain unchanged pending the user's own legal/parody review.
METHtalities remained the official term. The Mature-rated humor and the
"pokes fun at everybody, ends wholesome" moral direction were preserved.

### 23:04:27 UTC --- User

> proceed with creating the first file:
>
> 1.  GAME_BIBLE.md
>
> This should include: core identity premise tone world antagonist
> roster stages METHtality system campaign structure ending direction
> canon rules

**Reconstructed assistant-side outcome:** `GAME_BIBLE.md` was created as
the story/world source of truth. The current uploaded version is v1.1
and includes the core identity, premise, tone, Mature rating, fictional
world, Tripp's role and motivation, the 15 playable fighters, rivalries,
stages, METHtality system, campaign acts, ending direction, and canon
rules.

### 23:10:28 UTC --- User

> let's proceed with creating the gdd.md file:
>
> GDD.md
>
> This should include: game overview target platform gameplay loop
> controls combat systems modes character system stage system campaign
> flow UI requirements art direction audio direction production phases
>
> ==========
>
> make sure to do any research you need to do to make it as accurate as
> possible

**Reconstructed assistant-side outcome:** `GDD.md` was created as the
implementation-oriented game design document. It separates the
story/world canon from gameplay and production requirements. It covers
platform targets, Godot, gameplay loop, controls, combat states and
frame data, hitboxes/hurtboxes/pushboxes, health and meter, METHtality
trigger direction, AI, modes, character data, stage systems, campaign
flow, UI, pixel-art direction, audio, and production phases. It was
informed by Godot and fighting-game implementation research.

### 23:20:32 UTC --- User

> let's proceed with creating the gdd.md file:
>
> GDD.md
>
> This should include: game overview target platform gameplay loop
> controls combat systems modes character system stage system campaign
> flow UI requirements art direction audio direction production phases
>
> ==========
>
> make sure to do any research you need to do to make it as accurate as
> possible

**Reconstructed assistant-side outcome:** This was a repeated request
for the GDD deliverable. The surviving assistant response states that
`GDD.md` was created and provided as a download. The response also noted
research into Godot export/platform workflow, input/action handling, 2D
sprite animation, UI/audio systems, and future rollback-netcode
planning.

### 23:29:00 UTC --- User

> proceed with creating CHARACTERS.md, use the web to do any research
> you need for our characters and make sure it doesn't contradict our
> other files.

**Reconstructed assistant-side outcome:** `CHARACTERS.md` was created as
a roster design document. It defines each fighter's story layers,
gameplay archetype, strengths and weaknesses, working move kit, unique
METHtality, art direction, dialogue flavor, and ending. It also includes
Tripp as a separate non-playable boss entry, rivalry planning, a
character data template, initial balance spread, prototype priority, and
AI guardrails. The current file is v0.1.

### 23:36:12 UTC --- User

> for the rest of the files you create, don't print them here, just give
> me the link to download them and i will check the file.
>
> next up research and provide me the STAGES.md file

**Reconstructed assistant-side outcome:** This established a persistent
file-delivery preference: for future Sidewalk Showdown documents,
provide the downloadable file link rather than pasting the document
contents into chat. `STAGES.md` was created as a stage bible. It defines
12 stages, stage-specific narrative and visual direction, gameplay
readability requirements, layer structure, technical metadata, Godot
implementation notes, audio, background gags, art prompts, production
priority, and QA guardrails.

## 2026-11-03 --- Archive request

### 03:10:20 UTC --- User

> please give me the full detailed chat conversation as a downloadable
> .md file, dont paste the output here so we can save tokens, just give
> me the file to download

**Reconstructed assistant-side outcome:** This archive was prepared as a
downloadable Markdown document. Because some earlier assistant turns are
not available word-for-word, the archive distinguishes recovered user
prompts from reconstructed summaries and project facts.

------------------------------------------------------------------------

# 3. Detailed story and canon decisions

## 3.1 Core premise

Tripp Vlogs is a washed-up YouTuber/livestreamer whose channel is dying.
During a desperate filming session at The Bus Stop, he accidentally
captures two local regulars fighting. Instead of helping, he zooms in
and records the altercation.

The clip goes viral. Tripp sees an opportunity to revive his channel
through conflict, outrage, memes, reaction videos, and sponsor
attention.

He announces **Sidewalk Showdown**, a livestreamed winner-takes-all
fighting tournament. The prize is advertised as a life-changing package
that may include money, fame, housing, redemption, and a fresh start.
The details are deliberately vague and manipulative.

The fighters enter for personal, often ridiculous reasons: revenge,
money, respect, lost property, a grudge, a business scheme, a local
title, or a misunderstanding of the tournament flyer.

At first the event looks like trashy local entertainment. As the stream
grows, Tripp becomes more exploitative. He rigs matchups, invents
rivalries, manipulates the edit, uses misleading contracts, exaggerates
backstories, creates fake sponsor stunts, sells bootleg merchandise, and
dodges questions about the prize.

The fighters eventually compare notes and discover the scam. They
continue fighting because their own pride, grudges, and goals still
matter, but they begin turning Tripp's production against him.

The tournament winner reaches the end expecting the prize. Tripp refuses
to pay and invokes a hidden clause requiring the champion to face the
tournament commissioner. Tripp enters the arena as the hidden final
boss.

## 3.2 Tripp Vlogs --- antagonist rules

Tripp is:

-   The main antagonist.
-   The creator and host of the tournament.
-   A manipulator, commentator, scammer, and content exploiter.
-   The only boss in story/campaign mode.
-   A hidden final boss revealed only after the tournament bracket is
    won.
-   Not playable and not selectable.

Tripp is **not jealous of the fighters** and does not secretly admire
them. He thinks they are beneath him. He believes his fame and audience
make him more intelligent and important. He treats the fighters as raw
material for content.

His fatal flaw is arrogance: he underestimates the fighters' ability to
recognize a scam, compare information, work together temporarily, and
turn the live broadcast against him.

His boss style is not that of a trained martial artist. He uses
production gear, cheap spectacle, and influencer technology:

-   Selfie Stick Sweep
-   Ring Light Flash
-   Drone Drop
-   Comment Section Barrage
-   Sponsor Chug
-   Apology Armor
-   Thumbnail Trap
-   Algorithm Shift
-   Cancel Panic

His final arena is built around ring lights, drones, LED screens,
sponsor banners, livestream overlays, and production equipment. The boss
fight should feel like fighting Tripp's content machine, not a
conventional martial artist.

After defeat, the raw footage exposes Tripp, his contracts and lies
become public, sponsors abandon him, the chat turns on him, and his
apology video makes things worse. He survives, but his brand collapses.

## 3.3 Tone and moral direction

The game is intended to be Mature-rated and can include profanity, crude
jokes, raunchy banter, adult references, drunken stupidity, scam
culture, street violence, gross-out humor, black comedy, bad decisions,
and humiliating finishers.

The game is meant to poke fun at **everybody**. Nobody is fully
innocent, nobody is normal, and every character should be roast-worthy.

The comedy must remain character-specific. The fighters should not
become interchangeable joke props. Each one needs a distinctive
personality, motivation, insecurity, grudge, personal code, and moment
of agency.

The ending should be wholesome in a sideways way. The cast does not
become noble, respectable, or suddenly fixed. They recognize the bigger
scam, help expose Tripp, reclaim their stories, and become slightly more
loyal --- then go right back to arguing.

The requested tonal inspiration was the ensemble dysfunction and
character-driven absurdity of *It's Always Sunny in Philadelphia* and
*What We Do in the Shadows*.

## 3.4 World rules

The world is called **Sidewalk Florida**: a fictional Florida-inspired
arcade universe.

It should feel hot, loud, sticky, sunburned, neon-lit, overexposed,
grimy, and full of local history. Every gas station has a legend, every
dumpster has politics, every laundromat has rules, every flea-market
booth might be illegal, and every parking lot has a grudge attached to
it.

Canon excludes real towns, real brands, real businesses, real
neighborhoods, and real public figures. Stage names should be
place-types and local battlegrounds rather than specific towns.

------------------------------------------------------------------------

# 4. Playable roster and character direction

The roster contains 15 playable fighters. The current character document
uses the spelling **Raccoon Randy** (two c's), while the original user
prompt typed "Racoon Randy." No character renaming has been approved.

  ---------------------------------------------------------------------------
  Fighter           Gameplay identity Rival / conflict  METHtality
  ----------------- ----------------- ----------------- ---------------------
  Peg Leg Peggy     Scrappy trick     Stub Stan         **Walk the Plank**
                    fighter;                            --- improvised
                    improvised                          hardware/prosthetic
                    prosthetic and                      revenge
                    tool-based range                    

  Raccoon Randy     Wild rushdown /   Garbage Gretchen  **Trash Night** ---
                    feral grappler;                     raccoon swarm
                    trash-based                         enforces the trash
                    ambushes                            kingdom's bylaws

  Deputy Deranged   Bruiser /         Stabatha          **Stop Resisting**
                    mid-range control Christie; Whiskey --- fake arrest turns
                    fighter           Richard           into a
                                                        folding-barricade
                                                        beatdown

  Lt. Dan Hurricane Tank /            Burnout Bubba     **Category 5** ---
                    survivalist;                        cartoon storm debris
                    armor and heavy                     overwhelms the
                    knockdowns                          opponent

  Chuck Cheese      Chaos / gadget    Dogfood Debbie    **Party Room
  Felon             fighter; arcade                     Lock-In** --- cursed
                    junk and traps                      birthday room and
                                                        broken animatronics

  ShroomBoom Betty  Trap / confusion  Python Paulie     **Bad Trip** ---
                    fighter; spores                     psychedelic mushroom
                    and delayed                         panic
                    setups                              

  Python Paulie     Grappler /        ShroomBoom Betty  **Constrictor Kiss**
                    constrictor                         --- python
                    fighter; command                    constriction finish
                    grabs and                           
                    python-assisted                     
                    attacks                             

  Soapless Joe      Dirty speedster / Hairy Mary        **Stink Cloud** ---
                    evasive brawler                     cartoon grime cloud

  Whiskey Richard   Power brawler /   Deputy Deranged   **Flaming Belch** ---
                    fire gimmick                        cartoon whiskey-fume
                                                        fire burst

  Dogfood Debbie    Weird zoner /     Chuck Cheese      **Dinner Time** ---
                    bite fighter;     Felon             dinner bell summons
                    food projectiles                    cartoon strays
                    and stray-dog                       
                    chaos                               

  Burnout Bubba     Heavy bruiser;    Lt. Dan Hurricane **Road Rash** --- The
                    simple,                             Divorce Horse and
                    high-damage                         hot-pavement
                    gameplan                            spectacle

  Garbage Gretchen  Projectile /      Raccoon Randy     **Dumpster Dive** ---
                    zoning                              dumpster compactor
                    specialist; trash                   and trash-throne
                    control                             humiliation

  Stub Stan         Tough mid-range   Peg Leg Peggy     **Short Fuse** ---
                    fighter; low                        bench/plaque-themed
                    center of gravity                   explosive finish
                    and grounded                        
                    pressure                            

  Hairy Mary        Grappler /        Soapless Joe      **Bear Hug from
                    intimidation                        Hell** --- monstrous
                    fighter;                            hug and mobile-spa
                    close-range                         incident
                    command grabs                       

  Stabatha Christie Fast assassin /   Deputy Deranged   **Case Closed** ---
                    slash fighter;                      theatrical
                    feints and whiff                    fake-mystery finisher
                    punishes                            
  ---------------------------------------------------------------------------

### Character design rule

Every fighter needs five story layers:

1.  **Public reason:** What the character says they want.
2.  **Private reason:** What they actually care about.
3.  **What Tripp exploits:** The cheap angle Tripp uses for content.
4.  **What Tripp misunderstands:** The strength or dignity he fails to
    recognize.
5.  **How the fighter reclaims their story:** How they turn his edit
    against him.

Each fighter also needs a clear gameplay strength, weakness, basic
gameplan, beginner tactic, advanced tactic, rival matchup, signature
METHtality, and visual silhouette rule.

------------------------------------------------------------------------

# 5. Stage direction

The current stage bible defines 12 stages. They are recognizable
locations and local battlegrounds, not real towns.

  -----------------------------------------------------------------------
  Stage                   Function                Featured characters /
                                                  role
  ----------------------- ----------------------- -----------------------
  The Bus Stop            Origin stage; where     Opening and early
                          Tripp captures the      bracket; Stub Stan and
                          viral fight             the general roster

  The Liquor Store        Early local spectacle   Deputy Deranged and
                                                  Whiskey Richard

  Under the Bridge        Street-legend stage     Python Paulie and
                                                  Raccoon Randy

  Gas-N-Go                Sponsor corruption      ShroomBoom Betty and
                          begins                  Dogfood Debbie

  Dumpster Alley          Territory-war stage     Garbage Gretchen and
                                                  Raccoon Randy

  The Parking Lot         Public grudge           Burnout Bubba and Peg
                          battleground; first     Leg Peggy
                          greybox stage           

  The Encampment          Backstage /             Full roster
                          fighter-chemistry hub   

  The Drainage Canal      Late-bracket danger     Lt. Dan Hurricane,
                          stage                   Python Paulie, and
                                                  Burnout Bubba

  The Laundromat          Character-flavor stage  Soapless Joe and Hairy
                                                  Mary

  The Flea Market         Tournament becomes a    Chuck Cheese Felon and
                          local phenomenon        Dogfood Debbie

  The Alley Behind the    Semi-final pressure     Whiskey Richard and
  Bar                     cooker                  Stabatha Christie

  Tripp's Livestream      Hidden final-boss stage Tripp Vlogs
  Arena                   only                    
  -----------------------------------------------------------------------

## Stage design principles

-   Fighting readability comes first, comedy second, spectacle third.
-   Keep the fight floor visually simple.
-   Avoid high-contrast clutter directly behind fighter silhouettes.
-   Keep animated background gags behind the action.
-   Use strong value separation between fighters and backgrounds.
-   Hazards are visual-only for the prototype and baseline competitive
    play.
-   Interactive hazards, if ever added, belong in optional party modes
    or scripted campaign moments.
-   Tripp's Livestream Arena is reserved for the final boss sequence in
    story/campaign mode.

## Technical stage direction

The stage document recommends a 320x180 internal design resolution, 16:9
output, parallax layers, readable collision/floor geometry, consistent
camera bounds, and stage metadata. It references Godot 4's `Parallax2D`
and 2D lighting workflow, including `CanvasModulate`, for background
depth and lighting.

------------------------------------------------------------------------

# 6. METHtality system

**METHtality** is the official name for the playable fighters' cinematic
signature finishers.

The term is intentionally crude, adult, and in-world. It should not be
renamed unless the user explicitly approves it later.

Rules:

-   Every playable fighter has a unique METHtality.
-   It must be character-specific, not generic.
-   It should be funny, visually memorable, exaggerated, and readable.
-   It should fit the Mature-rated tone.
-   It should be absurd and arcade-like rather than realistic.
-   Tripp may promote the term as an edgy tournament feature; fighters
    can make fun of the branding.
-   The METHtality should feel like something only that fighter would
    do.

METHtalities are a planned system in the design documents; the Phase 1
greybox prototype did **not** implement them yet.

------------------------------------------------------------------------

# 7. Campaign structure

The campaign is character-based. Every playable fighter can complete the
story and receives a unique ending.

The tournament bracket is intentionally unreliable because Tripp
manipulates it for views. It does not need to be a mathematically
perfect single-elimination bracket.

## Main acts

-   **Act 0 --- The Clip:** Tripp films the bus-stop fight instead of
    helping. The clip goes viral.
-   **Act I --- Tournament Announcement:** Tripp pitches Sidewalk
    Showdown as a community opportunity with a vague, suspicious prize.
-   **Act II --- Early Bracket:** The local fighters enter and the petty
    rivalries become public entertainment.
-   **Act III --- The Stream Gets Bigger:** Tripp increases production,
    invents storylines, adds fake sponsors, and pushes contestants
    toward more conflict.
-   **Act IV --- The Scam Cracks Open:** Fighters compare stories and
    discover Tripp has been lying about the prize, contracts, and
    tournament conditions.
-   **Act V --- Late-Game Chaos:** The fighters keep competing while
    increasingly hijacking Tripp's production and exposing the scam.
-   **Act VI --- Hidden Boss:** Tripp refuses to pay and invokes the
    hidden clause. The final arena loads and Tripp becomes the only
    boss.
-   **Act VII --- Ending:** Tripp is defeated, the livestream exposes
    him, and each fighter receives a personal ending.

## Recommended full route

1.  Fighter introduction.
2.  Fight 1 --- Local opener.
3.  Fight 2 --- Personality clash.
4.  Fight 3 --- Rival fight.
5.  Fight 4 --- Sponsor/stunt fight.
6.  Fight 5 --- Scam-crack fight.
7.  Fight 6 --- Final tournament opponent.
8.  Hidden boss --- Tripp Vlogs.
9.  Fighter-specific ending.

A first campaign prototype should be much smaller: one fighter, three
regular fights, one Tripp boss placeholder, and one ending card. Burnout
Bubba was recommended as a strong first route because he is
beginner-friendly, has a simple heavy-bruiser gameplan, and has a clear
finale involving his scooter, The Divorce Horse.

------------------------------------------------------------------------

# 8. Art direction

The art direction combines retro arcade fighting games, dirty sidewalk
comedy, sunburned convenience-store color, exaggerated pixel characters,
cheap livestream overlays, fake sponsors, and grimy local folklore.

## Visual identity

-   8-bit / 16-bit-inspired pixel art.
-   Chunky, bold, sweaty, sun-blasted, grimy, colorful, and expressive.
-   Strong dark outlines for fighter readability.
-   No anti-aliasing on pixel sprites unless specifically approved for
    an exception.
-   Nearest-neighbor filtering.
-   Consistent pixel scale and pixel-grid discipline.
-   Distinct silhouettes before fine detail.
-   Background comedy and signage must not interfere with combat
    readability.
-   Fake livestream graphics and sponsor elements should feel cheap and
    bootleg.
-   The art should not drift into polished superhero comics, realistic
    crime drama, clean anime fighter art, generic fantasy brawler art,
    or inconsistent AI-art collage.

## Technical art targets

-   Recommended internal resolution: **320x180**.
-   Aspect ratio: **16:9**.
-   Suggested integer upscale: 4x to 1280x720, 6x to 1920x1080, 8x to
    2560x1440.
-   Standard fighter height target: approximately 64--96 pixels at base
    resolution, adjusted by character size.
-   Export stage layers separately: far background, parallax structures,
    midground props, spectators/background gags, fight floor, foreground
    framing, and lighting overlays.
-   Keep source art separate from runtime exports.
-   Use consistent pivots, sprite origins, naming, and import settings.

The user supplied rough level references, later available as
`BusStop.png` and `GasStation.png`. Additional uploaded reference images
include `CharacterMethtalities.png`, `CharacterMethtalities1.png`, and
`CharacterMethtalities2.png`.

------------------------------------------------------------------------

# 9. Game Design Document direction

`GDD.md` is the gameplay and implementation document, separate from the
story bible.

Its contents include:

-   Game overview and design pillars.
-   Target platform and export considerations.
-   Godot engine recommendation.
-   Core match loop and campaign loop.
-   Control philosophy and base layout.
-   Blocking and directional inputs.
-   Input buffering and remapping requirements.
-   Match rules and combat states.
-   Frame data and hitbox/hurtbox/pushbox rules.
-   Hit resolution and hitstop.
-   Health and Hype Meter.
-   METHtality trigger direction.
-   Combos, cancels, defense, and AI opponents.
-   Debug/training tools.
-   Story, arcade, versus, training, survival, tournament, gallery, and
    possible online modes.
-   Character data and animation requirements.
-   Stage loading, layer structure, and stage hazards.
-   Campaign flow and story delivery.
-   UI screens and HUD.
-   Pixel-art import rules and asset folder structure.
-   Audio identity, music, sound effects, voice, and mixing.
-   Production phases.

Online/rollback networking is treated as a later concern, not a
prerequisite for the first playable prototype.

------------------------------------------------------------------------

# 10. Organization and AI-assisted workflow

A major project goal is to keep the work organized and easy for both the
user and AI assistants to understand.

The surviving documents establish this source-of-truth stack:

1.  `GAME_BIBLE.md` --- story, world, tone, character, stage, and canon
    truth.
2.  `GDD.md` --- gameplay systems and implementation requirements.
3.  `CHARACTERS.md` --- roster and character-specific design.
4.  `STAGES.md` --- stage narrative, art, audio, and technical design.
5.  `CAMPAIGN_STRUCTURE.md` --- campaign routes, acts, scenes, and story
    flags.
6.  `ART_DIRECTION.md` --- visual standards and asset pipeline.
7.  `AI_WORKFLOW.md` --- how AI tools should read, propose, create, and
    review work.
8.  `CURRENT_STATE.md` --- the current implementation snapshot.
9.  `ROADMAP.md` --- production phases and sequencing.
10. `TASKS.md` --- actionable task tracker.
11. Phase closeout documents --- evidence of what was completed and
    validated.

## AI workflow rules

-   Read the canon documents before proposing story, art, or gameplay
    changes.
-   Distinguish canon from proposals and experiments.
-   Do not silently change character names, roster count, Tripp's role,
    the METHtality term, or the ending direction.
-   Do not introduce real towns, brands, businesses, or public figures
    into canon.
-   Do not make Tripp playable or add another boss.
-   Do not expand the roster or stage list without a reason and
    approval.
-   Prefer small, auditable changes.
-   Preserve existing gameplay behavior when doing refactors or
    documentation updates.
-   Report what changed, what was validated, and what remains uncertain.
-   Do not claim to have changed a repository, external tool, or file
    unless the action actually succeeded.
-   Keep the user's review/approval in the loop for canon and major
    production decisions.

## File-delivery preference

The user explicitly requested that future Sidewalk Showdown documents
not be pasted into chat. Provide a downloadable file link and let the
user review it. This preference applies to subsequent project-file
creation unless the user changes it.

------------------------------------------------------------------------

# 11. Technical implementation history recovered from project files

The production records supplied with this conversation are dated
primarily **2026-05-30 through 2026-05-31**. They are a historical
snapshot and may not reflect every repository change made after that
date.

## 11.1 Repository and engine snapshot

  Item                 Recorded value
  -------------------- ------------------------------------------
  Repository path      `/home/lch/projects/SidewalkShowdown`
  Branch               `main`
  GitHub remote        `violentwave/SidewalkShowdown` (private)
  Engine               Godot 4.6.3 stable
  Install method       Flatpak, app ID `org.godotengine.Godot`
  Godot project root   `Game/`
  Main scene           `res://Scenes/Main/Main.tscn`
  Internal viewport    320x180
  Stretch mode         `canvas_items`
  Texture filter       Nearest

## 11.2 Phase 0 --- Project setup and source of truth

The setup phase established the project root, documentation hierarchy,
naming conventions, asset-import rules, and task tracking. The intended
result was a repository that a solo developer and AI assistants could
navigate without relying on undocumented chat context.

## 11.3 Phase 1 --- Greybox combat prototype

**Recorded status: CLOSED on 2026-05-30.**

The prototype proved that two placeholder fighters could fight on a
basic stage. Completed systems included:

-   Main scene and match scene.
-   Greybox stage with floor, walls, bounds, and spawn points.
-   Two shared placeholder fighters.
-   Horizontal movement, jumping, crouching, and facing.
-   Hurtbox, pushbox, and hitbox debug overlays.
-   Light and heavy attacks with startup, active, and recovery timing.
-   Hit detection and prevention of repeated hits from the same swing.
-   Directional blocking and crouch blocking.
-   Hitstun, blockstun, and hitstop.
-   Health bars and health numbers.
-   Timer, KO, round-over, reset, and best-of-three match flow.
-   Data-driven universal light/heavy move definitions in
    `Game/Data/Moves/basic_attacks.json`.
-   Debug/training controls.

The prototype intentionally did **not** yet include final art, full
character movesets, specials, throws, supers, combos, METHtalities,
campaign, AI, menus, audio, online play, or rollback networking.

### Controls recorded in the Phase 1 closeout

  -----------------------------------------------------------------------
  Action                  Player 1                Player 2
  ----------------------- ----------------------- -----------------------
  Move left/right         A / D                   Left / Right arrows

  Jump                    W                       Up arrow

  Crouch                  S                       Down arrow

  Light attack            J                       Numpad 1

  Heavy attack            K                       Numpad 2

  Block                   Hold away from          Hold away from
                          opponent; down-away for opponent; down-away for
                          crouch block            crouch block
  -----------------------------------------------------------------------

Debug/training controls recorded there:

-   `R` --- reset round/match state.
-   `F1` --- toggle debug boxes.
-   `F2` --- refill both health bars.
-   `F3` --- toggle infinite time.
-   `F5` --- deal 100 raw damage to Player 1.
-   `F6` --- deal 100 raw damage to Player 2.

**Control-map caution:** A later project-context summary available to
this archive mentions a different mapping (P1 arrows + Z/X; P2 WASD +
1/2) and later F4/F7 debug functions. The uploaded Phase 1 closeout
contains the table above. Verify the live repository before relying on
either mapping; do not assume this historical document is the latest
input configuration.

## 11.4 Phase 2 --- Vertical slice

The uploaded project records show the following subphases complete:

  -----------------------------------------------------------------------
  Subphase                            Recorded result
  ----------------------------------- -----------------------------------
  2A --- Character data stubs and     Character index and JSON stubs for
  test matchup                        Burnout Bubba and Peg Leg Peggy;
                                      fallback loading; debug matchup
                                      configuration

  2B --- Placeholder identity and     Bubba/Peggy palettes, silhouette
  palettes                            hints, fighter names in HUD

  2C --- Stage blockout/style pass    The Parking Lot placeholder stage,
                                      preserving the existing stage
                                      geometry/API

  2D --- AnimationPlayer sync v0      Placeholder visual state feedback
                                      using Tween-based modulation

  2E --- Input buffering v0           State-gated light/heavy input
                                      buffer, approximately four frames /
                                      0.067 seconds

  2F --- Camera shake/zoom hooks      Cosmetic hit/block/KO camera
                                      feedback with a kill switch

  2G --- Static typing pass           Typed target scripts and functions;
                                      no intended gameplay behavior
                                      changes

  2H --- Variable jump height v0      Early jump-key release cuts upward
                                      velocity by a 0.5 multiplier
  -----------------------------------------------------------------------

### Phase 2G validation

The static-typing closeout records successful Godot editor load,
headless match boot, JSON validation, documentation drift check, and
phase-gate check. It records annotation-only changes and no intended
gameplay changes.

### Phase 2H behavior

-   Holding jump through ascent produces a full-height jump.
-   Releasing jump early while rising applies one jump cut.
-   The jump-cut multiplier is 0.5.
-   Releasing during descent does not cut the jump.
-   The cut state resets on a new jump and on full reset.
-   Both players are supported through the existing input-prefix
    pattern.

The closeout records Godot editor validation, headless match boot,
documentation drift, and phase-gate checks as passing.

### Next step in the uploaded historical snapshot

`CURRENT_STATE.md`, `ROADMAP.md`, and `TASKS.md` record Phase 2H as
complete. The next options were:

-   **Phase 2I --- Debug God Mode / Invulnerability (Optional)**, or
-   **Phase 2J --- Vertical Slice Playtest & Closeout**.

The next major production block was Phase 3 --- Special Moves & AI. A
later project-context summary also mentioned a basic AI opponent toggle
on F7, but that later implementation state is not confirmed by the
uploaded 2026-05-31 closeout records.

------------------------------------------------------------------------

# 12. Project files represented in the supplied materials

The following files were present in the supplied project materials when
this archive was assembled:

  -----------------------------------------------------------------------------------------
  File                                                  Purpose
  ----------------------------------------------------- -----------------------------------
  `GameBible.md`                                        Earlier/revised game-bible source
                                                        material

  `GAME_BIBLE.md`                                       Current story/world canon document,
                                                        v1.1

  `GDD.md`                                              Game design and implementation
                                                        document, v0.1

  `CHARACTERS.md`                                       Character roster and fighter
                                                        sheets, v0.1

  `STAGES.md`                                           Stage bible and technical stage
                                                        standards, v0.1

  `CAMPAIGN_STRUCTURE.md`                               Story-mode route and campaign
                                                        structure, v0.1

  `ART_DIRECTION.md`                                    Pixel-art style and production
                                                        standards, v0.1

  `AI_WORKFLOW.md`                                      AI-assisted production rules and
                                                        templates, v0.1

  `CURRENT_STATE.md`                                    Historical implementation snapshot,
                                                        dated 2026-05-31

  `ROADMAP.md`                                          Production roadmap

  `TASKS.md`                                            Task tracker

  `PHASE1_CLOSEOUT.md`                                  Phase 1 greybox prototype closeout,
                                                        dated 2026-05-30

  `PHASE2G_STATIC_TYPING_CLOSEOUT.md`                   Static typing closeout, dated
                                                        2026-05-31

  `PHASE2H_VARIABLE_JUMP_HEIGHT_CLOSEOUT.md`            Variable jump-height closeout,
                                                        dated 2026-05-31

  `Pasted markdown.md`                                  Revised story-bible draft
                                                        clarifying Tripp's contempt for the
                                                        fighters

  `Pasted markdown(1).md`                               Revised story-bible draft
                                                        incorporating the core canon
                                                        corrections

  `SIDEWALK_SHOWDOWN_NON_DEFINING_ASSET_PROMPTS.md`     Non-defining/reusable asset prompt
                                                        collection

  `sidewalk_showdown_non_defining_asset_prompts.json`   Structured version of reusable
                                                        asset prompts

  `sidewalk_showdown_non_defining_asset_prompts.csv`    Tabular version of reusable asset
                                                        prompts
  -----------------------------------------------------------------------------------------

### Uploaded visual references

-   `BusStop.png`
-   `GasStation.png`
-   `CharacterMethtalities.png`
-   `CharacterMethtalities1.png`
-   `CharacterMethtalities2.png`

The images are referenced here by their supplied filenames; this archive
does not claim to reproduce their visual contents.

------------------------------------------------------------------------

# 13. Known consistency notes and unresolved decisions

These are not new canon changes. They are items to verify or decide
during future project work.

1.  **Raccoon Randy spelling:** The original user prompt typed "Racoon
    Randy." Current project documents standardize the display name as
    **Raccoon Randy**. No name change was approved; this is treated as a
    spelling normalization in the documents.
2.  **ShroomBoom Betty code ID:** `CHARACTERS.md` contains a note about
    choosing one canonical script/data ID. The recommended ID in that
    file is `shroomboom_betty`. The display name remains ShroomBoom
    Betty.
3.  **Controls:** The Phase 1 closeout and later project-context summary
    show different key mappings. Verify the current project input map
    and update the documentation source of truth.
4.  **Stage hazards:** The stage bible says hazards should remain
    visual-only for the prototype and baseline competitive play.
    Interactive hazards are only a possible later feature for optional
    party modes or scripted campaign moments.
5.  **METHtality implementation:** METHtalities are part of the design
    canon, but were not implemented in the Phase 1 greybox prototype.
6.  **Tripp implementation:** Tripp's boss design is specified in the
    story and design documents, but the Phase 1 prototype did not
    implement the boss.
7.  **Full roster implementation:** The design roster has 15 playable
    fighters, while the historical prototype only used placeholder data
    for Burnout Bubba and Peg Leg Peggy.
8.  **Campaign implementation:** The campaign structure is designed on
    paper; the historical prototype did not yet include campaign routes,
    dialogue, cutscenes, or endings.
9.  **Art status:** The visual style and art standards are documented,
    but the historical prototype still used placeholder visuals. The
    stage and character reference images are not proof that final game
    assets have been integrated.
10. **Document freshness:** The implementation snapshot and phase
    closeouts are dated 2026-05-30/31. Confirm the current Git
    repository before treating these as the latest implementation
    status.

------------------------------------------------------------------------

# 14. Working principles to carry forward

-   Preserve the user's canon unless explicitly asked to revise it.
-   Keep Tripp non-playable and reserve him as the only hidden final
    boss.
-   Keep all current character names and METHtality naming unchanged
    until the user approves a change.
-   Keep the setting fictional and stage names location-based rather
    than town-based.
-   Keep the Mature-rated, raunchy, everyone-gets-roasted comedy.
-   Preserve the ending's sideways-wholesome emotional direction.
-   Build the fighting game in validated phases rather than attempting
    all content at once.
-   Maintain a clear source of truth for story, gameplay, characters,
    stages, campaign, art, workflow, and production state.
-   Keep AI work auditable and prevent canon drift.
-   For future project documents, provide the downloadable file link
    without pasting the document body into chat.

------------------------------------------------------------------------

# 15. Final project statement

**Sidewalk Showdown** is a dirty, absurd, Mature-rated arcade fighter
about a washed-up livestreamer who turns a bus-stop fight into a
winner-takes-all tournament because he thinks the people he films are
beneath him. He rigs the event, exploits the contestants, and tries to
own their stories. The fighters eventually expose him, defeat him in his
own livestream arena, and reclaim the spotlight.

The game should be funny, violent, crude, visually readable,
mechanically satisfying, and full of characters who are disasters in
very specific ways. It should roast everyone without losing its heart.

**Tripp thinks he owns the show. The fighters prove they are the show.**
