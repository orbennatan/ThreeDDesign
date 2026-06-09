## 2026-05-28 10:00 - Profiling deck_only.scad to CSV
- Analyzed [models/deck_only.scad](models/deck_only.scad) to identify all steel profiles and their roles.
- Extracted dimensions (height, width, wall thickness) and calculated instance counts for each profile role.
- Translated profile names into English, Arabic, and Hebrew.
- Generated [deck_profile_schedule.csv](deck_profile_schedule.csv) with the following columns: Name in English, Name in Arabic, Name in Hebrew, Number, profile type, profile height, profile width, metal width.
- Counts:
    - Main Longbar (RHS 60x40x3): 4
    - Transverse Latitude (RHS 40x40x2): 17
    - Support Pole (RHS 40x40x3): 13
    - Railing Post (RHS 40x40x3): 6
    - Vertical Railing Bar (Solid 10x10): 91
    - Handrail Tube (Round 30x2): 2
## 2026-06-09 00:00 - Review newest model stairs
- Checked the newest model file in [models/deck_only - Copy.scad](models/deck_only%20-%20Copy.scad) and traced the stair geometry.
- Confirmed the stair walking line reaches local x = -4017 mm, with the outer stair edge extending to about -4033 mm east of the stair origin.
- Logged the file timestamp order to identify the newest model before answering.

## 2026-06-09 15:04 - Redesigned stairs as a compact winding spiral
- Asked: redesign the stairs to keep winding all the way down and minimise their east reach, with the hard constraint that stairs must not penetrate any wall (file was reset to original first).
- Built validation tool design_winding_stairs.py (wall-collision via dense perimeter sampling, SAT tread overlap with headroom-awareness, floor-slab bounds, east-reach metric).
- Found the limiting geometry: L-shaped walls (leg A x[0,150] y[-1640,0]; leg B x[-1100,0] y[-1640,-1790]) + floor slab y>=-1900. Compared options: single-turn spiral (~-2363), wide partial spiral (~-3756), hairpin (infeasible on this floor).
- User chose Option A (compact single-turn spiral). Applied to models/deck_only - Copy.scad:
    - Replaced stair_path (15 pts) with the validated spiral: descends south, loops east around the wall (footprint reaches ~-2363 mm vs old -4017 mm, ~41% less east), returns north under the deck, lands at local (-590,22) directly below the deck connection.
    - Replaced the hardcoded stair_segment_angles table with computed function stair_segment_angle(i)=atan2(dx,dy) so tread orientation auto-follows the path (verified it reproduces the original angles, e.g. seg0 = -177.9 deg).
- Validation: no tread footprint hits either wall; landing on the slab; OpenSCAD compile exit 0 (no errors).
- Note/tradeoff accepted by user: the loop sweeps ~900 mm north under the deck and headroom at loop closure is ~1830 mm.

## 2026-06-09 15:37 - Stairs reworked to 1.5-turn winder finishing north
- Asked: make the stairs complete ~270 deg and finish with the lowest step facing NORTH (not west). Later clarified the floor may be extended NORTH as much as needed and treads may cross into +y at floor z.
- Key geometric finding: a stair that descends SOUTH off the deck and finishes heading NORTH must turn ~180 deg or ~540 deg; a literal 270 deg turn finishes facing EAST/WEST, never north. Verified via design_winding_stairs.py search (zero feasible 270 deg north-ending paths).
- Presented two validated north-ending options: half-turn ~180 deg (east -3367, worse east) and 1.5 turns ~540 deg (east -1877, most compact). User chose the 1.5-turn.
- Updated design_winding_stairs.py: replaced the 270deg-arc search with search_north_ending(target_deg) (south-first descent, total-turn match, north-finish, wall + slab checks; SOUTH_LIMIT=-1900, north unbounded) and a report of the 180/540 options.
- Applied to models/deck_only - Copy.scad: replaced stair_path (15 pts) with the 1.5-turn spiral. Descends south-east off the deck (veers to clear the E-W wall), winds 1.5 turns about a central newel, bottom tread heads north (dx,dy=64,287) ending at local (-1323,506). East reach ~-1877 mm (vs old -4017, ~53% less east). stair_segment_angle stays computed (atan2(dx,dy)).
- Validation: no tread footprint hits either wall; treads y in [-666,1202] (north extension used, south edge OK); steps ~294 mm; OpenSCAD compile exit 0.

## 2026-06-09 - Round 3: 180deg south->north tip-rounding stair (west bulge)
- Asked: stairs start heading SOUTH, dive to reach the south wall around the EAST TIP of leg B (local -1100,-1640), then curve another ~90deg to finish with the lowest tread heading NORTH. Total 180deg. West bulge approved by user.
- Built a 3-arc walking-line generator (build_threearc) + search_apex_on_wall in design_winding_stairs.py; ranks for deepest tread beside the wall, single-valley, ends north, no wall penetration, no self-overlap.
- Found geometric limit: a 1 m-wide tread cannot tuck closer than ~500-800 mm west of the tip while diving south (east edge would penetrate leg B), and the walking-line center cannot go below ~-1400 (south corner would run off the -1900 slab edge). Best path: south tread corner -1747 (past -1640 wall face), apex tread center (-1914,-1247), U bulges west to x=-3104.
- Applied the new 15-point stair_path to models/deck_only - Copy.scad (replaced the prior 1.5-turn 540deg spiral). Updated the explanatory comment. stair_segment_angle stays computed.
- Validated: no wall hits, no self-overlap, single valley (apex idx 7), start heading -90 (south), end heading +90 (north). OpenSCAD compile EXIT=0.
- Files: models/deck_only - Copy.scad, design_winding_stairs.py, plot_path.py (ASCII top-down debug map).
