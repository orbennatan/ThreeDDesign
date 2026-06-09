// --- DECK ONLY: 4-BAR FRAME WITHOUT STAIRS ---
show_labels = true;
$fn = 64;

// --- 1. MATERIAL GRADES & PROFILES ---
main_h = 60; main_w = 40; main_wall = 3.0;
lat_h  = 40; lat_w = 40; lat_wall = 2.0;
joist_h = 60;
joist_w = 40; joist_wall = 3.0;
pole_h = 40; pole_w = 40; pole_wall = 3.0;
ipe_thick = 20;
ipe_w = 140; ipe_gap = 1;
plate_w = 180; plate_d = 180; plate_thick = 10;
level_bolt_d = 16; level_bolt_h = 120;

// Recommended profiles for structural railing posts
rpost_w = 40; rpost_h = 40; rpost_wall = 3.0;

// --- 2. DECK DIMENSIONS ---
deck_len = 5950; deck_wid = 3040;
deck_elev = 2380;
bar_spacing = 380;
lat_count = ceil((deck_len - main_w) / bar_spacing) + 1;
lat_spacing = (deck_len - main_w) / (lat_count - 1);
reductions = [0, 740, 1060, 1300, 1450, 1540, 1590, 1610, 1610];

// --- MODULES ---

// RHS oriented along X axis
module steel_rhs(l, w, h, wall) {
    difference() {
        color("SlateGray") cube([l, w, h]);
        translate([-1, wall, wall]) cube([l+2, w-(wall*2), h-(wall*2)]);
    }
}

// Specialized RHS oriented along Y axis
module steel_rhs_y(w, l, h, wall) {
    difference() {
        color("SlateGray") cube([w, l, h]);
        translate([wall, -1, wall]) cube([w-(wall*2), l+2, h-(wall*2)]);
    }
}

module flush_pole(h, w_match, h_match) {
    color("DimGray")
    difference() {
        cube([h_match, w_match, h]);
        translate([pole_wall, pole_wall, -1]) cube([h_match-(pole_wall*2), w_match-(pole_wall*2), h+2]);
    }
}

module leveling_plate() {
    color("DarkSlateGray")
        cube([plate_w, plate_d, plate_thick]);

    color("Black") {
        for (x = [25, plate_w - 25])
            for (y = [25, plate_d - 25])
                translate([x, y, plate_thick])
                    cylinder(h = level_bolt_h, d = level_bolt_d);
    }
}

module adjustable_rock_support(h) {
    translate([-plate_w/2 + pole_w/2, -plate_d/2 + pole_w/2, 0])
        leveling_plate();

    translate([0, 0, plate_thick])
        flush_pole(h - plate_thick, pole_w, pole_w);
}

// Structural post height increased to pass through wood/latitudes to weld to the main steel frame
module structural_rail_post(post_height = 1160) {
    color("DarkSlateGray") difference() {
        cube([rpost_w, rpost_h, post_height]);
        translate([rpost_wall, rpost_wall, -1])
            cube([rpost_w - 2*rpost_wall, rpost_h - 2*rpost_wall, post_height + 2]);
    }
}

// --- ASSEMBLY ---

// A. FULL DECK FRAME
translate([0, 0, deck_elev]) {
    difference() {
        union() {
            // 4 primary longbars running North-South (X axis)
            longbar_ys = [0, 1000, 2000, deck_wid - main_w];
            longbar_reductions = [0, 1212, 1553, 1610];

            for (i = [0 : 3]) {
                y = longbar_ys[i];
                x_start = longbar_reductions[i];
                translate([x_start, y, 0]) steel_rhs(deck_len - x_start, main_w, main_h, main_wall);
            }

            // Transverse Latitude Profiles running East-West (Y axis) on top of the longbars
            for (i = [0 : lat_count - 1]) {
                x = i * lat_spacing;
                translate([x, 0, main_h]) steel_rhs_y(main_w, deck_wid, lat_h, lat_wall);
            }

            // Ipe Wood Planks running North to South (X axis) crossing over the latitudes
            for (y = [0 : ipe_w + ipe_gap : deck_wid - ipe_w])
                translate([0, y, main_h + lat_h]) color("SaddleBrown") cube([deck_len, ipe_w, ipe_thick]);
        }

        // Cutout for the South side arch
        translate([0, 0, -10])
            linear_extrude(main_h + lat_h + ipe_thick + 20)
                polygon([
                    [-200, -200], [-200, deck_wid + 200], [1610, deck_wid + 200],
                    [1610, deck_wid], [1610, 2660], [1590, 2280], [1540, 1900],
                    [1450, 1520], [1300, 1140], [1060, 760], [740, 380], [0, 0], [0, -200]
                ]);
        }
}

// B. ADJUSTABLE ROCK-WALL SUPPORTS
longbar_ys = [0, 1000, 2000, deck_wid - main_w];
longbar_reductions = [0, 1212, 1553, 1610];
rock_heights = [0, deck_elev/3, 2*deck_elev/3, deck_elev - 180];

for (i = [0 : 3]) {
    y = longbar_ys[i];
    rock_z = rock_heights[i];
    support_h = deck_elev - rock_z;
    reduction = longbar_reductions[i];

    // 2 supports per bar, evenly spaced between the two extreme anchor points
    // (south end at x=reduction, north end at x=deck_len).
    for (s = [1 : 2]) {
        x_supp = reduction + s * (deck_len - reduction) / 3;
        translate([x_supp, y + main_w/2 - pole_w/2, rock_z])
            adjustable_rock_support(support_h);
    }
}

// --- COMPASS LABELS ---
rail_z0 = deck_elev + main_h + lat_h + ipe_thick;

if (show_labels) {
    label_size = 400;
    label_z    = rail_z0 + 1;
    color("Red") {
        translate([deck_len/2, -label_size - 200, label_z]) linear_extrude(2) text("EAST", size = label_size, halign = "center");
        translate([deck_len/2, deck_wid + 200, label_z]) linear_extrude(2) text("WEST", size = label_size, halign = "center");
        translate([-200, deck_wid/2, label_z]) rotate([0, 0, 90]) linear_extrude(2) text("SOUTH", size = label_size, halign = "center");
        translate([deck_len + 200, deck_wid/2, label_z]) rotate([0, 0, 90]) linear_extrude(2) text("NORTH", size = label_size, halign = "center");
    }

    beam_label_size = 300;
    beam_ys = [0, 1000, 2000, deck_wid - main_w];
    color("Yellow")
        for (i = [0 : len(beam_ys) - 1])
            translate([deck_len/2, beam_ys[i] + main_w/2, label_z + 80])
                linear_extrude(20)
                    text(str(i), size = beam_label_size, halign = "center", valign = "center");
}

// --- RAILINGS (North + East edges) ---
rail_h     = 1100;
rail_bar   = 10;
rail_gap   = 90;
rail_pitch = rail_bar + rail_gap;
top_d    = 30;
top_wall = 2;

module top_tube(L) {
    rotate([0, 90, 0])
        difference() {
            cylinder(h = L, d = top_d);
            translate([0, 0, -1]) cylinder(h = L + 2, d = top_d - 2 * top_wall);
        }
}

translate([0, 0, deck_elev + main_h]) structural_rail_post();
translate([deck_len/3 - rpost_w/2, 0, deck_elev + main_h]) structural_rail_post();
translate([2*deck_len/3 - rpost_w/2, 0, deck_elev + main_h]) structural_rail_post();
translate([deck_len - rpost_w, 0, deck_elev + main_h]) structural_rail_post();
translate([deck_len - rpost_w, deck_wid/2, deck_elev + main_h]) structural_rail_post();
translate([deck_len - rpost_w, deck_wid - rpost_h, deck_elev + main_h]) structural_rail_post();

// East railing filling (y = 0)
color("DimGray") translate([0, 0, rail_z0]) {
    n_e = floor((deck_len - rail_bar) / rail_pitch) + 1;
    off_e = (deck_len - (n_e * rail_bar + (n_e - 1) * rail_gap)) / 2;
    for (i = [0 : n_e - 1]) translate([off_e + i * rail_pitch, 0, 0]) cube([rail_bar, rail_bar, rail_h]);
    translate([0, rail_bar / 2, rail_h - top_d / 2]) top_tube(deck_len);
}

// North railing filling (x = deck_len)
color("DimGray") translate([deck_len - rail_bar, 0, rail_z0]) {
    n_n = floor((deck_wid - rail_bar) / rail_pitch) + 1;
    off_n = (deck_wid - (n_n * rail_bar + (n_n - 1) * rail_gap)) / 2;
    for (i = [0 : n_n - 1]) translate([0, off_n + i * rail_pitch, 0]) cube([rail_bar, rail_bar, rail_h]);
    translate([rail_bar / 2, 0, rail_h - top_d / 2]) rotate([0, 0, 90]) top_tube(deck_wid);
}
