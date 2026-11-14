# Verity's Burger Run (Godot 4.4+)

Open `project.godot` in Godot 4.4 or newer (the first open imports the sprites), then press F5.

## Controls
| Action | Keys |
|---|---|
| Move | A / D or arrow keys |
| Jump | Space, W or Up |
| Line attack (3 pts, 30 dmg, pierces everything in a straight line) | J (faces the way you look) or left mouse (aims at the cursor) |
| Burst attack (2 pts, 20 dmg to enemies within 30 px) | K or right mouse |
| Restart after dying | Space |

## Rules
- Verity: 200 HP. Soldier bullets: 10 damage. Soldiers: 50 HP.
- Soldiers fire a bullet in a straight line at the spot Verity was standing when they fired.
- The chef (ally) throws burgers with terrible aim. Catch one = +1 point (max 10) and Verity gets fatter:
  0-2 pts design 1, 3-5 design 2, 6-8 design 3, 9-10 design 4. Spending points makes him slimmer again.
- Clear all soldiers to advance. 3 levels: 3, 5 and 7 soldiers.
- On death you are asked to restart; Space restarts the level you died on (full HP, 0 points).

## Tweaking
- Level layouts: `scripts/level_data.gd`
- Verity stats / attacks: top of `scripts/player.gd`
- Chef aim: `aim_error_deg` in `scripts/chef.gd` (higher = worse aim)
- Soldier fire rate / bullet speed per level: top of `scripts/level.gd`
