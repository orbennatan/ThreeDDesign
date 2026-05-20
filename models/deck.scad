// --- FULL DECK FRAME & PERFECTLY ALIGNED 2-STAGE STAIRS ---
show_labels = true;
$fn = 64;

// --- 1. MATERIAL GRADES & PROFILES ---
main_h = 100; main_w = 50; main_wall = 4.0;
joist_h = 100; joist_w = 50; joist_wall = 4.0;
pole_h = 100; pole_w = 50; pole_wall = 4.0;
ipe_thick = 20; ipe_w = 140; ipe_gap = 5;

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

            // Add cross supports for IPE wood every 380 mm (for screwing)
            for (x_screw = [0 : 380 : deck_len])
                translate([x_screw, 0, main_h - joist_h])
                    steel_rhs(main_w, deck_wid, joist_h, joist_wall);
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
translate([p2_x + 1000 - pole_h, -main_w,  0]) flush_pole(p2_z, main_w, pole_h);

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

