# Brainrot School: Enchanted Academy

A Roblox brainrot game for make.fun's roblox-brainrot-01 bounty: a magic forest
school where students collect absurd school-themed brainrots, carry them home
to their classroom, and climb a ladder of rarities, mutations and rebirths —
while rivals pull, push and steal, a lunch rush stampedes the field, and a
naughty crow raids unlocked classrooms.

## The game

- **Loop:** brainrots walk the Parade Lane in front of the academy — click one
  to buy it, carry it home, place it on a pedestal in your classroom, and watch
  the money tick. Buy the next tier, then the next.
- **Cast:** 60 original brainrots in 15 tiers (Common to PRINCIPAL), each with
  a name, a tier colour and a dollars-per-second label. Income roughly doubles
  per tier, from $5/s to $80,000/s. Mutations multiply income: GOLD x2,
  DIAMOND x3, LAVA x4, RAINBOW x6, GLITCH x10.
- **PvP:** PULL [Q] yanks a carrier toward you and slows them; PUSH [F] shoves
  a carrier and can knock their brainrot loose ("DROPPED!"); STEAL [E] takes a
  brainrot off a rival's unlocked base. Your own classroom is a safe zone.
- **Quests:** three chapters (Murid Baru, Naik Kelas, Bintang Sekolah) plus
  three rotating daily quests, all paying cash, with a QUEST DONE! banner.
- **Machines:** the Gacha Machine by the cafeteria (Press [E], $1,000 a roll
  for a random brainrot) and the Fuse Lab by the gym (Press [E], fuse three
  brainrots of one tier into one of the next). Benches and swings in the arena
  seat you with Press [E] SIT and grant a Fresh +10% income buff.
- **Events:** the LUNCH RUSH! stampede every 90 seconds and Gagak Nakal, the
  crow thief, every 2 minutes. A base lock [L] shields you from both.
- **Progression:** rebirths (+1x income each), five upgrades (speed, bag,
  lock, slots, luck), and a 60-entry Report Card with an income bonus.
- **Arena:** rare brainrots spawn only on high places — the gym climbing wall,
  the big tree, the academy tower — so players meet where the PvP happens.

## Layout

- `src/server/` — one module per system (world, spawning, carrying, stealing,
  pull/push, quests, hazard, crow, rebirth, upgrades, income, lock, state).
  The server owns all state; the client only renders and asks.
- `src/client/Game.client.luau` — the HUD (money top-centre, quests on the
  right, lock/rebirth/report-card/upgrades at the bottom) and the key bindings
  through ContextActionService.
- `src/shared/` — the catalog, tuning, quest and upgrade data both sides read.
- `default.project.json` — the Rojo project; `game.rbxl` is built from it.
  The whole 3D school is built from code by WorldBuilder when the server
  starts: no Studio-pasted models.

## Build and check

    rojo build default.project.json --output game.rbxl
    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

`main.ts` (Node 22, standard library only) copies `game.rbxl`, `src/`,
`screenshots/` and `PLAY.json` to the output directory and writes
`dossier.json` with the vendored make.fun library. `PLAY.json` names the
published place once the owner has published it from Studio.
