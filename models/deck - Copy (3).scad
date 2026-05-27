// --- FULL DECK FRAME & PERFECTLY ALIGNED 2-STAGE STAIRS ---
show_labels = true;
$fn = 64;

// --- 1. MATERIAL GRADES & PROFILES ---
main_h = 100; main_w = 50; main_wall = 4.0;
joist_h = 100; joist_w = 50; joist_wall = 4.0;
pole_h = 100; pole_w = 50; pole_wall = 4.0;
ipe_thick = 20; ipe_w = 140; ipe_gap = 1;

// --- 2. DECK DIMENSIONS ---
deck_len = 5950; deck_wid = 3040;
deck_elev = 2380; // 14 steps * 170mm
bar_spacing = 380;
reductions = [0, 740, 1060, 1300, 1450, 1540, 1590, 1610, 1610];

// --- 3. STAIR SPECS ---
step_h = 170; step_tread = 280; step_w = 1000;
num_steps = 7;

// Welded steel stair profiles
stair_str_h    = 160;  // inclined stringer RHS height (perp to slope)
stair_str_w    = 60;   // inclined stringer RHS width
stair_str_wall = 4;

stair_slope_len = num_steps * sqrt(step_tread*step_tread + step_h*step_h);
stair_angle     = atan(step_h / step_tread);

// --- MODULES ---
module steel_rhs(l, w, h, wall) {
    difference() {
        color("SlateGray") cube([l, w, h]);
        translate([-1, wall, wall]) cube([l+2, w-(wall*2), h-(wall*2)]);
    }
}

module flush_pole(h, w_match, h_match) {
    color("DimGray")
    difference() {
        cube([h_match, w_match, h]);
        translate([pole_wall, pole_wall, -1]) cube([h_match-(pole_wall*2), w_match-(pole_wall*2), h+2]);
    }
}

// Single inclined RHS stringer. The TOP edge sits one ipe_thick below
// local z=0 so a full-width tread placed with its top at z=0 lands
// flush on the stringer at the back of step 0.
module straight_stringer() {
    translate([0, 0, -ipe_thick])
        rotate([0, stair_angle, 0])
            translate([0, 0, -stair_str_h])
                steel_rhs(stair_slope_len, stair_str_w, stair_str_h, stair_str_wall);
}

// Stair flight = 2 stringers + per step: 2 short vertical RHS risers
// welded on top of the stringers at the front of the tread + 1 Ipe
// tread spanning the full step width. Tread is supported at all 4
// corners (back on stringer tops, front on risers).
module stair_flight() {
    straight_stringer();
    translate([0, step_w - stair_str_w, 0]) straight_stringer();

    for (i = [0 : num_steps - 1]) {
        tread_top   = -i * step_h;
        z_str_front = -(i + 1) * step_h - ipe_thick;

        translate([(i + 1) * step_tread - stair_str_w, 0, z_str_front])
            steel_rhs(stair_str_w, stair_str_w, step_h, stair_str_wall);
        translate([(i + 1) * step_tread - stair_str_w, step_w - stair_str_w, z_str_front])
            steel_rhs(stair_str_w, stair_str_w, step_h, stair_str_wall);

        translate([i * step_tread, 0, tread_top - ipe_thick])
            color("SaddleBrown")
                cube([step_tread, step_w, ipe_thick]);
    }
}

// --- ASSEMBLY ---

// A. FULL DECK FRAME
translate([0, 0, deck_elev]) {
    difference() {
        union() {
            // 9 long bars (joists) with gradually reduced lengths
            for (i = [0 : 8]) {
                y = i == 0 ? 0 : (i == 8 ? deck_wid - main_w : i * bar_spacing);
                x_start = reductions[i];
                translate([x_start, y, 0]) steel_rhs(deck_len - x_start, main_w, main_h, main_wall);
            }

            // Ipe Wood (Parallel to 3040mm)
            for (x = [0 : ipe_w + ipe_gap : deck_len - ipe_w])
                translate([x, 0, main_h]) color("SaddleBrown") cube([ipe_w, deck_wid, ipe_thick]);
        }

        // Cutout for the South side arch
        translate([0, 0, -10])
            linear_extrude(main_h + ipe_thick + 20)
                polygon([
                    [-200, -200],
                    [-200, deck_wid + 200],
                    [1610, deck_wid + 200],
                    [1610, deck_wid],
                    [1610, 2660],
                    [1590, 2280],
                    [1540, 1900],
                    [1450, 1520],
                    [1300, 1140],
                    [1060, 760],
                    [740, 380],
                    [0, 0],
                    [0, -200]
                ]);
    }
}

// B. SUPPORT POLES (from ground up to deck, placed only where the deck is not cut by the arch)
for (i = [0 : 8]) {
    y = i == 0 ? 0 : (i == 8 ? deck_wid - main_w : i * bar_spacing);
    for (s = [1 : 3]) {
        x_supp = s * deck_len / 4;
        reduction = reductions[i];
        if (x_supp > reduction) {
            translate([x_supp, y + main_w/2 - pole_w/2, 0]) flush_pole(deck_elev, pole_w, pole_w);
        }
    }
}

// B. SUPPORT POLES (now included under each long bar, see above)

// C. STAIRCASE SYSTEM
// 1. Upper Podest (100x100cm)
translate([0, -1000, deck_elev]) {
    steel_rhs(1000, 1000, main_h, main_wall);

    // 2. Flight 1 (Parallel, descending in +X)
    // Lifted by main_h so the first tread top aligns with the podest deck surface.
    translate([1000, 0, main_h]) stair_flight();
}

// 3. Lower Podest (100x100cm)
p2_x = 1000 + (num_steps * step_tread);
p2_z = deck_elev - (num_steps * step_h);

translate([p2_x, -1000, p2_z]) {
    steel_rhs(1000, 1000, main_h, main_wall);

    // 4. Flight 2 (90-degree right turn, descending in -Y)
    // Same main_h lift so its first tread is flush with the lower podest top.
    rotate([0, 0, -90]) translate([0, 0, main_h]) stair_flight();
}

// 5. PODEST SUPPORT POSTS (welded vertical RHS legs)
// Upper podest: only front legs needed; back edge is welded to deck frame.
translate([0,            -1000, 0]) flush_pole(deck_elev, main_w, pole_h);
translate([1000 - pole_h, -1000, 0]) flush_pole(deck_elev, main_w, pole_h);

// Lower podest: free-standing, all four corners.
translate([p2_x,                 -1000,    0]) flush_pole(p2_z, main_w, pole_h);
translate([p2_x + 1000 - pole_h, -1000,    0]) flush_pole(p2_z, main_w, pole_h);
translate([p2_x,                 -main_w,  0]) flush_pole(p2_z, main_w, pole_h);
// NW corner pole united with the east-most long beam's support: extends
// all the way up to deck_elev and spans across y=0 so it sits under both
// the lower-podest NW corner AND the east-most long beam above.
translate([p2_x + 1000 - pole_h, -main_w,  0]) flush_pole(deck_elev, 2 * main_w, pole_h);

// --- COMPASS LABELS ---
//   y = 0          edge -> EAST   (upper podest is connected here)
//   y = deck_wid   edge -> WEST
//   x = 0          edge -> SOUTH  (short side nearest upper podest)
//   x = deck_len   edge -> NORTH
if (show_labels) {
    label_size = 400;
    label_z    = deck_elev + main_h + ipe_thick + 1;
    color("Red") {
        // y = 0 (long edge, near upper podest) = EAST
        translate([deck_len/2, -label_size - 200, label_z])
            linear_extrude(2) text("EAST", size = label_size, halign = "center");
        // y = deck_wid (long edge) = WEST
        translate([deck_len/2, deck_wid + 200, label_z])
            linear_extrude(2) text("WEST", size = label_size, halign = "center");
        // x = 0 (short edge, near upper podest) = SOUTH
        translate([-200, deck_wid/2, label_z]) rotate([0, 0, 90])
            linear_extrude(2) text("SOUTH", size = label_size, halign = "center");
        // x = deck_len (short edge) = NORTH
        translate([deck_len + 200, deck_wid/2, label_z]) rotate([0, 0, 90])
            linear_extrude(2) text("NORTH", size = label_size, halign = "center");
    }

    // Long-beam numbers (1 = east @ y=0 ... 9 = west @ y=deck_wid-main_w)
    // Labels sit on top of each beam at its NORTH end.
    beam_label_size = 200;
    beam_ys = [
        for (i = [0 : 8]) i == 0 ? 0 : (i == 8 ? deck_wid - main_w : i * bar_spacing)
    ];
    color("Yellow")
        for (i = [0 : len(beam_ys) - 1])
            translate([deck_len - 300, beam_ys[i] + main_w/2, label_z])
                linear_extrude(2)
                    text(str(i + 1), size = beam_label_size, halign = "center", valign = "center");
}

// --- RAILINGS (North + East edges) ---
rail_h     = 1100;        // total height above deck surface
rail_bar   = 10;          // solid square bar, 10 x 10 mm
rail_gap   = 100;         // clear space between bars (10 cm)
rail_pitch = rail_bar + rail_gap; // 110 mm centre-to-centre

// Round top rail (hand rail): 30 mm OD, 2 mm wall (standard steel tube)
top_d    = 30;
top_wall = 2;

// Hollow round top tube of length L, centerline along +X starting at origin.
// Outer top of tube is at z = +top_d/2 (so callers position it so the
// tube's top edge sits at the desired rail height).
module top_tube(L) {
    translate([0, 0, 0])
        rotate([0, 90, 0])
            difference() {
                cylinder(h = L, d = top_d);
                translate([0, 0, -1])
                    cylinder(h = L + 2, d = top_d - 2 * top_wall);
            }
}

rail_z0 = deck_elev + main_h + ipe_thick; // top of IPE planks

// East railing: along y = 0, x from 0 to deck_len
color("DimGray")
translate([0, 0, rail_z0]) {
    // vertical bars
    for (x = [0 : rail_pitch : deck_len - rail_bar])
        translate([x, 0, 0]) cube([rail_bar, rail_bar, rail_h]);
    // round top tube, centered on bar line, top of tube at z = rail_h
    translate([0, rail_bar / 2, rail_h - top_d / 2])
        top_tube(deck_len);
}

// North railing: along x = deck_len, y from 0 to deck_wid
color("DimGray")
translate([deck_len - rail_bar, 0, rail_z0]) {
    for (y = [0 : rail_pitch : deck_wid - rail_bar])
        translate([0, y, 0]) cube([rail_bar, rail_bar, rail_h]);
    translate([rail_bar / 2, 0, rail_h - top_d / 2])
        rotate([0, 0, 90]) top_tube(deck_wid);
}

// Generic straight rail run of length L, oriented along +X.
// Vertical bars sit on z=0; round top tube tops out at z = rail_h.
module rail_run(L) {
    color("DimGray") {
        for (x = [0 : rail_pitch : L - rail_bar])
            translate([x, 0, 0]) cube([rail_bar, rail_bar, rail_h]);
        translate([0, rail_bar / 2, rail_h - top_d / 2])
            top_tube(L);
    }
}

// --- STAIR / PODEST RAILINGS ---

// Upper podest (x=0..1000, y=-1000..0, z=deck_elev)
// Open sides: south (x=0) and west (y=-1000).
// Rails sit on top of the podest steel plate (z = deck_elev + main_h)
// so rail height matches the stair rails at the top tread.
translate([0, -1000, deck_elev + main_h]) {
    // West side: rail along x=0..1000 at y=0 (world y=-1000)
    rail_run(1000);
    // South side: rail along y=0..1000 at x=0 (world x=0)
    translate([rail_bar, 0, 0]) rotate([0, 0, 90]) rail_run(1000);
}

// Stair rail with gravity-vertical bars and an inclined round top tube.
// Origin at the top of the flight, on the stair surface (top tread).
// Bars rise straight up (world +Z) from the slope.
module stair_rail(side_y) {
    color("DimGray") {
        for (x = [0 : rail_pitch : num_steps * step_tread - rail_bar])
            translate([x, side_y, -x * step_h / step_tread])
                cube([rail_bar, rail_bar, rail_h]);
        // Inclined round top tube: tube top at z = rail_h at x=0,
        // descending parallel to the slope.
        translate([0, side_y + rail_bar / 2, rail_h - top_d / 2])
            rotate([0, stair_angle, 0])
                top_tube(stair_slope_len);
    }
}

// Flight 1: descends in +X from upper podest to lower podest.
// Flight-local y=0 -> world y=-1000 (south, away from deck),
//             y=step_w -> world y=0 (next to deck's east rail).
// South (outer) side: full-height stair rail with gravity-vertical bars.
translate([0, -1000, deck_elev]) translate([1000, 0, main_h])
    stair_rail(0);

// Deck-facing side of flight 1: short vertical bars rising from each
// tread up to the deck-rail base (rail_z0). No top rail here - the deck's
// east rail provides the top boundary, so we just fill the open gap.
color("DimGray")
for (i = [0 : num_steps - 1])
    for (xo = [0 : rail_pitch : step_tread - rail_bar])
        translate([1000 + i * step_tread + xo,
                   0,
                   deck_elev + main_h - i * step_h])
            cube([rail_bar,
                  rail_bar,
                  rail_z0 - (deck_elev + main_h - i * step_h)]);

// Lower podest (x=p2_x..p2_x+1000, y=-1000..0, z=p2_z)
// Open sides: north (y=0) and east (x=p2_x+1000).
// Rails sit on top of the podest steel plate so they match both the
// bottom of flight 1's rail and the top of flight 2's rail.
translate([p2_x, -1000, p2_z + main_h]) {
    // North side: rail along x=0..1000 at y=1000 (world y=0)
    translate([0, 1000 - rail_bar, 0]) rail_run(1000);
    // East side: rail along y=0..1000 at x=1000 (world x=p2_x+1000)
    translate([1000, 0, 0]) rotate([0, 0, 90]) rail_run(1000);
}

// Flight 2: rotated -90 from flight 1, descends in -Y.
// Both sides get gravity-vertical bars + inclined top rail.
translate([p2_x, -1000, p2_z]) rotate([0, 0, -90]) translate([0, 0, main_h]) {
    stair_rail(0);
    stair_rail(step_w - rail_bar);
}

