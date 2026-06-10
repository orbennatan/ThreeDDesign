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

## 2026-06-09 - Stair rail vertical balusters (match deck)
- Asked: give the staircase rail vertical bars like the deck.
- Added module stair_rail_balusters(offset) in models/deck_only - Copy.scad: walks each stair segment, places rail_bar-square (10mm) vertical cubes of height rail_h at rail_pitch (100mm) spacing along both rail offsets (+/-stair_width/2), interpolating position and z. Tops align with the sloping top rail since stair_level_z is linear in node index.
- Called it from curved_stair_rails() for both sides. Reused deck rail params (rail_bar=10, rail_gap=90, rail_pitch=100, rail_h=1100).
- Validated: OpenSCAD compile EXIT=0.
- Files: models/deck_only - Copy.scad.

## 2026-06-10 - Located eastmost point of lowest stair
- Asked: xyz of the eastmost point in the lowest part of the lowest stair.
- Active model: models/deck_only - Copy.scad. Lowest stair = tread i=13 (14-riser winding stair); built from midpoint of stair_path[12]->[13] (local (-3070,-224)), rotated -13.1deg, z=stair_top_z-13*stair_rise=396.4mm top.
- Eastmost corner (min model_y = min local_x): model (x,y)=(-191.3,-3591.0). Lowest face (bottom of steel cross-beams) z=316.4mm (wood underside 376.4, walking top 396.4).
- Answer: (x,y,z)=(-191.3, -3591.0, 316.4) mm in model space; east is -y (model=[local_y,local_x], east=negative local_x).

## 2026-06-10 - Corrected eastmost-point calc; Israeli riser check
- User: lowest stair should end at -2330; z per step per Israeli standards; recalculate.
- Coordinate fix: prior answer used absolute z (316.4) and the lowest BUILT tread (i=13). Switched to deck-relative z (stair top=0, floor=-2330=abs230).
- Drop already 2330; floor at z=-2330. Israeli std check: 14 risers, rise=166.4mm(16.6cm) in 15-17.5cm OK; going=300mm; 2R+G=63.3cm in 61-64 OK. 14 is only integer count keeping rise<=17.5cm.
- Eastmost point of floor-level step (i=14, midpoint path[13]->[14], angle 0): model (x,y,z)=(-78.0,-3604.0,-2330.0); east edge y=-3604 spans x=-78..222.
- Noted lowest BUILT tread (i=13) is one riser above floor at z(top)=-2163.6 (standard landing); model draws 13 treads (stair_visible_treads=13), floor is the landing. Offered to add a flush bottom tread at -2330 if wanted (understructure would dip to -2410 below slab).

## 2026-06-10 - Fixed stair geometry punching below floor (-2330)
- User: no part of the stair may go below z=-2330 (would require digging a hole).
- Diagnosed: treads OK (lowest understructure rel -2243.6); STRINGER beams in bottom segments 12-13 dipped to rel -2530 (200mm below floor abs 230).
- Fix in models/deck_only - Copy.scad curved_stair_stringers(): clamp each stringer centreline z to max(computed, stair_floor_z + stair_stringer_w/2) so underside rests ON the slab; bottom stringer flattens to floor instead of penetrating. Supports already stand on floor; rails above.
- Verified: lowest stair point now abs 230 = rel -2330 exactly, nothing below. OpenSCAD compile EXIT=0. Riser stays Israeli-standard 166.4mm.

## 2026-06-10 - Floor slab is now the last step (lowest tread one riser above -2330)
- User: last modeled stair should be one standard riser ABOVE the -2330 plane; the floor itself is the final step.
- Treads already ended at lowest tread top -2163.6 (=one rise 166.4mm above floor). Change in models/deck_only - Copy.scad curved_stair_stringers(): loop now [0:stair_visible_treads-1] (segments 0-12) so the final descending segment to the floor landing is no longer built; footing clamp retained so lowest stringer rests exactly on slab.
- Updated stair_path comment to state floor slab is the last step.
- Verified: lowest modeled tread top rel -2163.6 (one rise above floor); lowest of ALL stair structure rel -2330.0 = floor exactly, nothing below; rise 166.4mm (Israeli std). OpenSCAD EXIT=0.

## 2026-06-10 - Fixed stair rail balusters floating / not connected at bottom
- User: stair rail not connected to anything at the bottom. Rendered bottom (OpenSCAD PNGs) and confirmed all balusters floated ~one riser above the treads; bottom ones hovered above the floor.
- Root cause: off-by-one in stair_rail_balusters() - baluster base sat on the sloping walking line (stair_level_z(i)) while the flat tread beneath a segment is tread(i+1) at stair_level_z(i+1), a full rise lower.
- Fix in models/deck_only - Copy.scad stair_rail_balusters(): base_z = z1 = stair_level_z(i+1) (the tread it stands on; floor slab for the lowest segment since stair_level_z(14)=stair_floor_z); height = (z0+(z1-z0)*t + rail_h) - base_z so tops still meet the sloping top rail. Now every baluster foots on its tread and the bottom run lands on the floor.
- Verified: lowest baluster base rel -2330 = floor exactly, none below; bottom balusters on floor; OpenSCAD EXIT=0; re-render shows balusters resting on steps/floor.

## 2026-06-10 - Trimmed stair rail north overhang past last tread
- User: stair rail too long, extended north beyond the last actual stair.
- Cause: rail ran to the floor-landing node 14 (path[14], ~300mm/one going north of the last built tread at node 13).
- Fix in models/deck_only - Copy.scad: stair_rail_posts_and_top() rail_nodes end node 14 -> stair_visible_treads (13); stair_rail_balusters() loop [0:stair_risers-1] -> [0:stair_visible_treads-1] so the floor-landing segment gets no balusters.
- Verified via OpenSCAD renders: rail/posts/balusters now end flush at the last actual tread, no north overhang. Compile EXIT=0.

## 2026-06-10 - Uniform thin stair-rail supports (removed thick posts)
- User: stair rail vertical supports change from a thick profile to thin rods; make them uniform top-to-bottom. Chose: all thin rods (10x10).
- Fix in models/deck_only - Copy.scad stair_rail_posts_and_top(): removed the structural_rail_post (rpost 50x50) loop at rail_nodes; module now only draws the sloping top handrail tube. Vertical members are now exclusively the uniform 10x10 balusters from stair_rail_balusters().
- Verified render: all verticals uniform thin rods reaching the handrail; top rail intact; OpenSCAD EXIT=0.

## 2026-06-10 - Rail posts now tie handrail into stringers (mixed post+rod rail)
- User reverted the all-thin-rods change; wants structural posts connecting handrail to the stair support PLUS thin rods between for fall protection.
- Current file already had thick posts + thin balusters, but posts only rested on the tread top (120mm above stringer; not connected).
- Fix in models/deck_only - Copy.scad stair_rail_posts_and_top(): added post_foot_drop = ipe_thick + stair_stringer_drop (160mm); each structural_rail_post now starts at stair_level_z(i) - post_foot_drop with height rail_h + post_foot_drop, footing on the stringer centreline.
- Verified: post base embeds in stringer cube at all nodes 0,3,6,9,12,13 both sides; lowest base rel -2323.6 (>= floor); ~25mm lateral overlap with outer stringer; thin rods unchanged. OpenSCAD EXIT=0; render shows posts running into the side stringers.

## 2026-06-10 - Winding stringer: linear pieces now connect (mitred seams)
- User: the winding outer support (stringer) is not curved and its pieces don't connect; OK to approximate the curve with linear pieces but every joint must weld all four sides; applies to all parts.
- Root cause: curved_stair_stringers() built each segment from stair_offset_point(seg,...) using that segment's own normal, so adjacent segments' shared node mapped to different offset points -> gaps.
- Fix in models/deck_only - Copy.scad: added function stair_seam_point(i,off) = mitred offset shared by both segments at node i (avg of adjacent segment normals, scaled 1/cos(half-angle), clamped 0.35 for sharp turns; ends clamped straight). curved_stair_stringers() now uses seam points for p0/p1, so segment seg end == segment seg+1 start (xy and z identical) for all 3 offset lines (outer/center/inner) and all segments.
- Verified: max joint xy gap = 0 (shared); offset held ~460-465mm; OpenSCAD compile EXIT=0; render shows continuous stringer with boxy weld knuckles at each node.

## 2026-06-10 - Handrail follows same mitred-seam curve as stringer; verticals plumb
- User: handrail should use the same curve method as the stringer, so vertical posts and thin rods simply go between stringers and handrail.
- Fix in models/deck_only - Copy.scad stair_rail_posts_and_top(): top handrail now built one solid_member_between piece PER STEP over segments [0:stair_visible_treads-1] using stair_seam_point(seg/seg+1, offset) at z=stair_level_z+rail_h-top_d/2 (was big jumps between nodes 0,3,6,9,12,13 via stair_node_offset_point). Posts now placed at stair_seam_point(i,offset) too. stair_rail_balusters() switched to stair_seam_point as well.
- Result: handrail approximates the winding curve with connected/mitred pieces (four-sided weld at each node), same as the stringer; posts and 10x10 rods share the seam line so they run straight (plumb) from stringer up to handrail. Rail offset 500, stringer outer 460 -> posts overlap stringer 25mm (tie-in retained).
- Verified: OpenSCAD compile EXIT=0; iso render shows continuous curved handrail with plumb rods; seam joints share points.
