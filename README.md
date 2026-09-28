# First Game (Don't Know What It's About Yet)

A 2D magic platformer made with [Godot](https://godotengine.org/) 4.7.

You play as a young mage fighting through a series of rooms. Each room's exit
stays sealed until every enemy is defeated. Clear a room and you choose one of
three **talents** (double jump, more damage, split bolts...). Some rooms also
unlock a new **fighting style**. The run ends with a boss: the Slime King.

## Fighting styles

| Style | How you get it | What it does |
|---|---|---|
| Arcane Bolt | Start | Fires magic bolts |
| Blade Dance | Clear room 2 | Fast sword-of-light combo, every 3rd hit is a big finisher |
| Frost Nova | Clear room 4 | Ice burst around you that damages and freezes enemies |

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | A / D or arrow keys | Left stick |
| Jump (hold for higher) | Space / W | A |
| Attack (hold to repeat) | J / Z / left click | X |
| Dash | K / X / Shift | B |
| Switch style | Q / E, or 1-3 | Shoulder buttons |
| Drop through a platform | S + Space | |
| Restart after win/loss | R | Start |

## Getting started

1. Install Godot 4.7 from https://godotengine.org/download
2. Clone this repository
3. Open Godot, click **Import**, and select the `project.godot` file in this folder
4. Press **F5** to play

## Changing the game

Everything is plain GDScript in `scripts/`. Good places to start:

- **Rooms:** `scripts/rooms.gd`. Each room is drawn with text (`#` stone, `=` platform,
  `s` slime, `b` bat, `D` door). Add a new entry to make a new room.
- **Talents:** `scripts/talents.gd` lists them; their effects live in `apply_talent()` in `scripts/game.gd`.
- **How she moves:** the numbers at the top of `scripts/player.gd` (jump height, speed, dash...).
- **Enemies:** `scripts/enemy.gd`.

The heroine and the enemies are drawn with code for now (see the `_draw()`
functions), so the game is fully playable before any art exists. Real sprites
can replace those later.

To jump straight to a room while testing, set **Project Settings > Editor > Run >
Main Run Args** to `-- --room=5`.

## Tests

`tests/smoke_test.tscn` plays through the whole game automatically: every room,
every style, the talent picker, the doors, the boss, dying and restarting.
Run it from this folder with:

```
godot --headless --path . res://tests/smoke_test.tscn
```

It prints `Smoke test PASSED` and exits with code 0 when everything works.
