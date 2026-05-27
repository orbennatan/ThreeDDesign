// --- ISOLATED TRUSS-STAIRCASE SYSTEM: 7 RISERS / 6 VISIBLE TREADS ---
show_labels = false;
$fn = 64;

// --- 1. MATERIAL GRADES & PROFILES ---
main_h = 60; main_w = 40; main_wall = 3.0;
ipe_thick = 20;
ipe_w = 140; ipe_gap = 1;
pole_h = 40; pole_w = 40; pole_wall = 3.0;
rpost_w = 40; rpost_h = 40; rpost_wall = 3.0;

// --- TRUSS PROFILE OPTIMIZATION ---
stair_str_h    = 80;
stair_str_w    = 40;
stair_str_wall = 3.0;

top_chord_h    = 80;
top_chord_w    = 40;
top_chord_wall = 3.0;

web_w          = 20;
web_wall       = 2.0;

// --- 2. GLOBAL REFERENCE HEIGHT ---
deck_elev = 2380;

// --- 3. STAIR SPECS ---
step_h = 170;
step_tread = 280;
step_w = 1000;

risers_per_flight = 7;
visible_treads = risers_per_flight - 1;

flight_run = visible_treads * step_tread;       // 6 * 280 = 1680
flight_drop = risers_per_flight * step_h;       // 7 * 170 = 1190
stringer_drop = visible_treads * step_h;        // 6 * 170 = 1020

rail_slope_len = sqrt(flight_run*flight_run + flight_drop*flight_drop);
rail_angle = atan(flight_drop / flight_run);

// --- 4. RAILING & TRUSS DIMENSIONS ---
rail_h     = 1100;
rail_pitch = 110;
rail_z0 = deck_elev + main_h + 40 + ipe_thick;

// --- UTILITY STRUCTURAL MODULES ---

module steel_rhs(l, w, h, wall) {
    difference() {
        color("SlateGray") cube([l, w, h]);
        translate([-1, wall, wall]) cube([l+2, w-(wall*2), h-(wall*2)]);
    }
}

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
        translate([pole_wall, pole_wall, -1])
            cube([h_match-(pole_wall*2), w_match-(pole_wall*2), h+2]);
    }
}

module structural_rail_post(post_height = 1160) {
    color("DarkSlateGray")
    difference() {
        cube([rpost_w, rpost_h, post_height]);
        translate([rpost_wall, rpost_wall, -1])
            cube([rpost_w - 2*rpost_wall, rpost_h - 2*rpost_wall, post_height + 2]);
    }
}

module standard_rail_run(L) {
    color("DimGray") {
        n = floor((L - 10) / 110) + 1;
        off = (L - (n * 10 + (n - 1) * 100)) / 2;

        for (i = [0 : n - 1])
            translate([off + i * 110, 0, 0])
                cube([10, 10, rail_h]);

        translate([0, 10 / 2, rail_h - 30 / 2])
            rotate([0, 90, 0])
                cube([30, 30, L]);
    }
}

// --- STAIRCASE CORE MODULES ---

module podest_frame() {
    translate([0, 0, 0])
        steel_rhs(1000, main_w, main_h, main_wall);

    translate([0, 1000 - main_w, 0])
        steel_rhs(1000, main_w, main_h, main_wall);

    translate([0, main_w, 0])
        steel_rhs_y(main_w, 1000 - 2*main_w, main_h, main_wall);

    translate([1000 - main_w, main_w, 0])
        steel_rhs_y(main_w, 1000 - 2*main_w, main_h, main_wall);

    translate([500 - main_w/2, main_w, 0])
        steel_rhs_y(main_w, 1000 - 2*main_w, main_h, main_wall);

    for (y = [0 : ipe_w + ipe_gap : 1000 - ipe_w]) {
        translate([0, y, main_h])
            color("SaddleBrown")
                cube([1000, ipe_w, ipe_thick]);
    }
}

// Stringer starts under the first lowered tread.
// The podest itself is the top walking surface.
module absolute_flush_stringer() {
    color("SlateGray")
    translate([0, stair_str_w, 0])
    rotate([90, 0, 0])
    linear_extrude(height = stair_str_w) {
        polygon([
            [0,          -step_h - ipe_thick],
            [flight_run, -flight_drop - ipe_thick],

            [flight_run, -flight_drop - ipe_thick - stair_str_h],
            [0,          -step_h - ipe_thick - stair_str_h]
        ]);
    }
}

// 6 visible treads.
// First tread is one riser below the podest.
module stair_flight_chassis() {
    absolute_flush_stringer();

    translate([0, step_w/2 - stair_str_w/2, 0])
        absolute_flush_stringer();

    translate([0, step_w - stair_str_w, 0])
        absolute_flush_stringer();

    for (j = [0 : visible_treads - 1]) {
        x0 = j * step_tread;
        tread_top = -(j + 1) * step_h;
        z_riser_bottom = -(j + 2) * step_h - ipe_thick;

        translate([x0, 0, tread_top - ipe_thick])
            color("SaddleBrown")
                cube([step_tread, step_w, ipe_thick]);

        translate([x0 + step_tread - stair_str_w, 0, z_riser_bottom])
            steel_rhs(stair_str_w, stair_str_w, step_h, stair_str_wall);

        translate([x0 + step_tread - stair_str_w, step_w/2 - stair_str_w/2, z_riser_bottom])
            steel_rhs(stair_str_w, stair_str_w, step_h, stair_str_wall);

        translate([x0 + step_tread - stair_str_w, step_w - stair_str_w, z_riser_bottom])
            steel_rhs(stair_str_w, stair_str_w, step_h, stair_str_wall);
    }
}

// --- INTEGRATED TRUSS MODULE ---

module integrated_stair_truss(side_y) {
    L_run = flight_run;
    n_webs = floor((L_run - web_w) / rail_pitch) + 1;
    off_web = (L_run - (n_webs * web_w + (n_webs - 1) * (rail_pitch - web_w))) / 2;

    weld_overlap = 10;
    post_positions = [0, L_run/2 - rpost_w/2, L_run - rpost_w];

    translate([0, side_y, rail_h - top_chord_h])
        rotate([0, rail_angle, 0])
            steel_rhs(rail_slope_len, top_chord_w, top_chord_h, top_chord_wall);

    // Structural guard posts: welded into the lower stringer and top chord.
    // The 20x20 webs below remain infill/truss members, not the primary lateral posts.
    for (x_post = post_positions) {
        x_mid = x_post + rpost_w/2;

        z_stringer_top = -step_h - ipe_thick - x_mid * (stringer_drop / flight_run);
        z_bottom = z_stringer_top - weld_overlap;

        z_top = rail_h - x_mid * (flight_drop / flight_run) - top_chord_h;

        translate([x_post, side_y + stair_str_w/2 - rpost_h/2, z_bottom])
            structural_rail_post(z_top - z_bottom);
    }

    color("LightSlateGray") {
        for (i = [0 : n_webs - 1]) {
            x = off_web + i * rail_pitch;

            z_stringer_top = -step_h - ipe_thick - x * (stringer_drop / flight_run);
            z_bottom = z_stringer_top - weld_overlap;

            z_top = rail_h - x * (flight_drop / flight_run) - top_chord_h;

            translate([x, side_y + stair_str_w/2 - web_w/2, z_bottom])
                steel_rhs(web_w, web_w, z_top - z_bottom, web_wall);
        }
    }
}

// --- ASSEMBLY OF STAIRCASE SYSTEM ---

p2_x = 1000 + flight_run;
p2_z = deck_elev - flight_drop;

// 1. Upper Podest
translate([0, -1000, deck_elev]) {
    podest_frame();

    translate([1000, 0, main_h + ipe_thick])
        stair_flight_chassis();
}

// 2. Lower Podest
translate([p2_x, -1000, p2_z]) {
    podest_frame();

    rotate([0, 0, -90])
        translate([0, 0, main_h + ipe_thick])
            stair_flight_chassis();
}

// 3. Podest Support Posts
translate([0,             -1000, 0])
    flush_pole(deck_elev, main_w, pole_h);

translate([1000 - pole_h, -1000, 0])
    flush_pole(deck_elev, main_w, pole_h);

translate([p2_x,                 -1000, 0])
    flush_pole(p2_z, main_w, pole_h);

translate([p2_x + 1000 - pole_h, -1000, 0])
    flush_pole(p2_z, main_w, pole_h);

translate([p2_x,                 -main_w, 0])
    flush_pole(p2_z, main_w, pole_h);

translate([p2_x + 1000 - pole_h, -main_w, 0])
    flush_pole(deck_elev, 2 * main_w, pole_h);

// --- INTEGRATED TRUSS & RAILINGS ASSEMBLY ---

// Structural Posts for Landings
translate([0, -1000, deck_elev + main_h])
    structural_rail_post();

translate([p2_x, -1000, p2_z + main_h])
    structural_rail_post();

translate([p2_x + 1000 - rpost_w, -1000, p2_z + main_h])
    structural_rail_post();

// Upper Podest Railings
translate([0, -1000, deck_elev + main_h + ipe_thick]) {
    standard_rail_run(1000);

    translate([10, 0, 0])
        rotate([0, 0, 90])
            standard_rail_run(1000);
}

// Flight 1 Truss
translate([0, -1000, deck_elev + main_h + ipe_thick])
    translate([1000, 0, 0])
        integrated_stair_truss(0);

// Flight 1 Inner Gap Fill
color("DimGray") {
    L_df = flight_run;
    n_df = floor((L_df - web_w) / rail_pitch) + 1;
    off_df = (L_df - (n_df * web_w + (n_df - 1) * (rail_pitch - web_w))) / 2;

    for (i = [0 : n_df - 1]) {
        x_local = off_df + i * rail_pitch;
        tread_index = min(visible_treads - 1, floor(x_local / step_tread));
        tread_top_z = deck_elev + main_h + ipe_thick - (tread_index + 1) * step_h;

        translate([1000 + x_local, 0, tread_top_z])
            cube([web_w, web_w, rail_z0 - tread_top_z]);
    }
}

// Lower Podest Railings
translate([p2_x, -1000, p2_z + main_h + ipe_thick]) {
    translate([0, 1000 - 10, 0])
        standard_rail_run(1000);

    translate([1000, 0, 0])
        rotate([0, 0, 90])
            standard_rail_run(1000);
}

// Flight 2 Truss
translate([p2_x, -1000, p2_z + main_h + ipe_thick])
rotate([0, 0, -90]) {
    integrated_stair_truss(0);
    integrated_stair_truss(step_w - stair_str_w);
}
