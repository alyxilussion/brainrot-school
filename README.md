# Brainrot School: Enchanted Academy

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/alyxilussion/brainrot-school/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard)
[![reward](https://make.fun/badge/roblox-brainrot-01/alyxilussion/brainrot-school/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A Roblox brainrot game for [make.fun](https://make.fun/bounty/roblox-brainrot-01)'s
**roblox-brainrot-01** bounty ("Make the best AI Roblox brainrot game", $1,000 in
USDC): a magic forest school where students collect absurd school-themed
brainrots, carry them home to their classroom, and climb a ladder of rarities,
mutations and rebirths — while rivals pull, push and steal, a lunch rush
stampedes the field, and a naughty crow raids unlocked classrooms.

![Brainrot School cover](screenshots/1-cover.jpg)

- **Play it:** https://www.roblox.com/games/79538854183879
- **Bounty:** https://make.fun/bounty/roblox-brainrot-01
- **Referral:** https://make.fun/r/87aq1dky

## The game

- **Loop:** brainrots walk the Parade Lane in front of the academy (a new one
  every 4 seconds) — click one to buy it, carry it home, place it on a
  pedestal in your classroom, and watch the money tick. Buy the next tier,
  then the next. You start with $100.
- **Cast:** 80 original brainrots in 16 tiers (Common, Uncommon, Rare, Epic,
  Legendary, Mythic, Divine, Hidden, Celestial, Galactic, Eternal, Godly,
  Supreme, Ultimate, PRINCIPAL, Secret), 4 per tier plus 20 Secret, each
  with a name, a tier colour and a dollars-per-second label. Income roughly
  doubles per tier, from $5/s (Pencil Penguin) to $786,432/s (Mystery Manta);
  the buy price is twelve times the income. Mutations multiply income:
  GOLD x2, DIAMOND x3, LAVA x4, RAINBOW x6, GLITCH x10.
- **PvP:** PULL [Q] yanks a carrier toward you and slows them (and may knock
  their brainrot loose); PUSH [F] shoves a carrier and usually knocks their
  brainrot loose ("DROPPED!" — anyone can grab it within 45 seconds); STEAL
  [E] takes a brainrot off a rival's unlocked base. A base lock [L] shields
  your classroom for 60 seconds (120 with the Long Lock upgrade).
- **Rival classmates:** NPC students Budi, Siti and Joko own classrooms of
  their own, with brainrots you can steal — and they send thieves to raid
  yours every 45 seconds.
- **Quests:** four chapters of four steps each — New Student, Troublemaker,
  Class Champion, School Star — plus a Bonus Board with three rotating quests that
  get harder (and pay more) every lap. Every chapter finished adds +5% income.
- **Machines:** the Gacha Machine by the cafeteria (Press [E], $1,000 a roll
  for a random brainrot, kinder odds than the parade) and the Fuse Lab by the
  gym (Press [E], fuse three brainrots of one tier into one of the next; three
  PRINCIPALs fuse into a random Secret).
- **Events:** the LUNCH RUSH! stampede every 100 seconds (15-second countdown,
  shelter in your base) and the Naughty Crow, the crow thief, every 130 seconds.
  A base lock shields you from both.
- **Rare spawns:** Mythic-or-better brainrots appear only on high places —
  the gym climbing wall, the big tree, the academy tower (every 45 seconds) —
  and an Arena Drop lands on the arena crest every 75 seconds, first grab
  wins.
- **Rest:** benches and swings in the arena seat you with Press [E] SIT and
  grant a Fresh +10% income buff for 60 seconds (2-minute cooldown).
- **Progression:** rebirths from $25,000 (+1x income each), five upgrades
  (Speed Shoes, Big Bag, Long Lock, Extra Slot, Lucky Charm), and a 60-entry
  Report Card that pays +2% income per entry collected.

## Layout

- `src/server/` — 12 scripts, one module per system: `init.server` (boot +
  respawn), `WorldBuilder` (the whole 3D school is built from code when the
  server starts: no Studio-pasted models), `BrainrotFactory` (characters
  built from Parts), `ParadeSpawner` (parade, high pads, Arena Drop),
  `CarrySystem`, `StealSystem`, `PullPushSystem`, `QuestSystem`,
  `RivalSystem` (Budi, Siti, Joko + their thieves), `ThreatSystem` (Lunch
  Rush + Naughty Crow), `EconomySystem` (income tick, shop, Gacha, Fuse,
  Rebirth, Fresh buff) and `PlayerState`. The server owns all state; the
  client only renders and asks.
- `src/client/` — `Hud.client.luau` (money, quests, lock/rebirth/report-card/
  upgrades, key bindings through ContextActionService) and
  `Effects.client.luau` (feedback effects).
- `src/shared/` — `BrainrotCatalog` (the 60 brainrots), `Config` (every
  tuning number + remote names) and `QuestCatalog` (chapters + Bonus Board),
  read by both sides.
- `default.project.json` — the Rojo project: `src/shared` →
  ReplicatedStorage, `src/server` → ServerScriptService, `src/client` →
  StarterPlayerScripts. `game.rbxl` is built from it.
- `screenshots/` — 4 real captures of the game running (see below);
  `PLAY.json` names the published place; `TOUR.json` names the keys that
  reach each screenshot; `main.ts` + `vendor/makefun-roblox.ts` build the
  dossier the judge reads.

## Build and check

    rojo build default.project.json --output game.rbxl
    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

`rojo build` builds `game.rbxl` from the Luau under `src/`; open it in
Roblox Studio to play or publish it. `main.ts` (Node 22, standard library
only) copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to the
output directory and writes `dossier.json` with the vendored make.fun
library. `PLAY.json` names the published place
(79538854183879, universe 10777954728).

## Screenshots

All four are real captures of the game running on the published place:

1. `1-cover.jpg` — carrying a DIAMOND LEGENDARY Pencil Shark home past a
   rival's classroom (also the game's first thumbnail on Roblox).
2. `2-academy.jpg` — the academy front, HUD and quest panel.
3. `3-report-card.jpg` — the Report Card grid, tiers up to PRINCIPAL.
4. `4-quests.jpg` — the Quests panel: four chapters + Bonus Board.
