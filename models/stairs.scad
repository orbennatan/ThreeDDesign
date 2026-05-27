// --- ISOLATED 2-STAGE STAIRCASE SYSTEM ---
show_labels = false; // Turned off as deck is removed
$fn = 64;

// --- 1. MATERIAL GRADES & PROFILES ---
main_h = 60; main_w = 40; main_wall = 3.0;
ipe_thick = 20;
ipe_w = 140; ipe_gap = 1;
pole_h = 40; pole_w = 40; pole_wall = 3.0;
rpost_w = 40; rpost_h = 40; rpost_wall = 3.0;

// --- 2. GLOBAL REFERENCE HEIGHT (Retained for matching original elevations) ---
deck_elev = 2380;

// --- 3. STAIR SPECS ---
step_h = 170; step_tread = 280; step_w = 1000;
num_steps = 7;
stair_str_h    = 160;
stair_str_w    = 60;   
stair_str_wall = 4;
stair_slope_len = num_steps * sqrt(step_tread*step_tread + step_h*step_h);
stair_angle     = atan(step_h / step_tread);

// --- 4. RAILING SPECS ---
rail_h     = 1100;
rail_bar   = 10;
rail_gap   = 100;
rail_pitch = rail_bar + rail_gap;
top_d    = 30;
top_wall = 2;
rail_z0 = deck_elev + main_h + 40 + ipe_thick; // 40 represents the original lat_h

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
        translate([pole_wall, pole_wall, -1]) cube([h_match-(pole_wall*2), w_match-(pole_wall*2), h+2]);
    }
}

module structural_rail_post(post_height = 1160) {
    color("DarkSlateGray") difference() {
        cube([rpost_w, rpost_h, post_height]);
        translate([rpost_wall, rpost_wall, -1]) 
            cube([rpost_w - 2*rpost_wall, rpost_h - 2*rpost_wall, post_height + 2]);
    }
}

module top_tube(L) {
    rotate([0, 90, 0])
        difference() {
            cylinder(h = L, d = top_d);
            translate([0, 0, -1]) cylinder(h = L + 2, d = top_d - 2 * top_wall);
        }
}

module rail_run(L) {
    color("DimGray") {
        n = floor((L - rail_bar) / rail_pitch) + 1;
        off = (L - (n * rail_bar + (n - 1) * rail_gap)) / 2;
        for (i = [0 : n - 1]) translate([off + i * rail_pitch, 0, 0]) cube([rail_bar, rail_bar, rail_h]);
        translate([0, rail_bar / 2, rail_h - top_d / 2]) top_tube(L);
    }
}

// --- STAIRCASE CORE MODULES ---

// Real structural frame for the landings including the top Ipe flooring
module podest_frame() {
    // Perimeter steel beams in X
    translate([0, 0, 0]) steel_rhs(1000, main_w, main_h, main_wall);
    translate([0, 1000 - main_w, 0]) steel_rhs(1000, main_w, main_h, main_wall);
    // Perimeter steel beams in Y
    translate([0, main_w, 0]) steel_rhs_y(main_w, 1000 - 2*main_w, main_h, main_wall);
    translate([1000 - main_w, main_w, 0]) steel_rhs_y(main_w, 1000 - 2*main_w, main_h, main_wall);
    // Center structural reinforcement beam
    translate([500 - main_w/2, main_w, 0]) steel_rhs_y(main_w, 1000 - 2*main_w, main_h, main_wall);

    // Landing Ipe wood planks layer
    for (y = [0 : ipe_w + ipe_gap : 1000 - ipe_w]) {
        translate([0, y, main_h]) color("SaddleBrown") cube([1000, ipe_w, ipe_thick]);
    }
}

// Inclined structural beam supporting the stair step risers
module straight_stringer() {
    translate([0, 0, -step_h - ipe_thick])
        rotate([0, stair_angle, 0])
            steel_rhs(stair_slope_len, stair_str_w, stair_str_h, stair_str_wall);
}

// Stair flight with two parallel side stringers to support 1-meter span steps
module stair_flight() {
    straight_stringer(); // Left side stringer
    translate([0, step_w - stair_str_w, 0]) straight_stringer(); // Right side stringer
    
    for (i = [0 : num_steps - 1]) {
        tread_top   = -i * step_h;
        z_str_front = -(i + 1) * step_h - ipe_thick;

        // Vertical support risers welded onto both side stringers
        translate([(i + 1) * step_tread - stair_str_w, 0, z_str_front])
            steel_rhs(stair_str_w, stair_str_w, step_h, stair_str_wall);
        translate([(i + 1) * step_tread - stair_str_w, step_w - stair_str_w, z_str_front])
            steel_rhs(stair_str_w, stair_str_w, step_h, stair_str_wall);
            
        // Wood step tread
        translate([i * step_tread, 0, tread_top - ipe_thick])
            color("SaddleBrown")
                cube([step_tread, step_w, ipe_thick]);
    }
}

// Stair railing run
module stair_rail(side_y) {
    L = num_steps * step_tread;
    n = floor((L - rail_bar) / rail_pitch) + 1;
    off = (L - (n * rail_bar + (n - 1) * rail_gap)) / 2;
    color("DimGray") {
        for (i = [0 : n - 1]) {
            x = off + i * rail_pitch;
            translate([x, side_y, -x * step_h / step_tread]) cube([rail_bar, rail_bar, rail_h]);
        }
        translate([0, side_y + rail_bar / 2, rail_h - top_d / 2]) rotate([0, stair_angle, 0]) top_tube(stair_slope_len);
    }
}


// --- ASSEMBLY OF STAIRCASE SYSTEM ---

// Derived coordinates for landing 2
p2_x = 1000 + (num_steps * step_tread);
p2_z = deck_elev - (num_steps * step_h);

// 1. Upper Podest (100x100cm)
translate([0, -1000, deck_elev]) {
    podest_frame(); 
    // 2. Flight 1
    translate([1000, 0, main_h + ipe_thick]) stair_flight();
}

// 3. Lower Podest (100x100cm)
translate([p2_x, -1000, p2_z]) {
    podest_frame();
    // 4. Flight 2
    rotate([0, 0, -90]) translate([0, 0, main_h + ipe_thick]) stair_flight();
}

// 5. PODEST SUPPORT POSTS
translate([0,              -1000, 0]) flush_pole(deck_elev, main_w, pole_h);
translate([1000 - pole_h, -1000, 0]) flush_pole(deck_elev, main_w, pole_h);
translate([p2_x,                 -1000,    0]) flush_pole(p2_z, main_w, pole_h);
translate([p2_x + 1000 - pole_h, -1000,    0]) flush_pole(p2_z, main_w, pole_h);
translate([p2_x,                 -main_w,  0]) flush_pole(p2_z, main_w, pole_h);
translate([p2_x + 1000 - pole_h, -main_w,  0]) flush_pole(deck_elev, 2 * main_w, pole_h);


// --- STAIR / PODEST RAILINGS ASSEMBLY ---

translate([0, -1000, deck_elev + main_h]) structural_rail_post();
translate([p2_x, -1000, p2_z + main_h]) structural_rail_post();
translate([p2_x + 1000 - rpost_w, -1000, p2_z + main_h]) structural_rail_post();

// Upper podest railing run
translate([0, -1000, deck_elev + main_h + ipe_thick]) {
    rail_run(1000);
    translate([rail_bar, 0, 0]) rotate([0, 0, 90]) rail_run(1000);
}

// Flight 1 Outer Rail
translate([0, -1000, deck_elev]) translate([1000, 0, main_h + ipe_thick]) stair_rail(0);

// Flight 1 Inner Gap Filler Railing
color("DimGray") {
    L_df = num_steps * step_tread;
    n_df = floor((L_df - rail_bar) / rail_pitch) + 1;
    off_df = (L_df - (n_df * rail_bar + (n_df - 1) * rail_gap)) / 2;
    for (i = [0 : n_df - 1]) {
        x_local = off_df + i * rail_pitch;
        i_step = min(num_steps - 1, floor(x_local / step_tread));
        tread_top_z = deck_elev + main_h + ipe_thick - i_step * step_h;
        translate([1000 + x_local, 0, tread_top_z]) cube([rail_bar, rail_bar, rail_z0 - tread_top_z]);
    }
}

// Lower podest railing run
translate([p2_x, -1000, p2_z + main_h + ipe_thick]) {
    translate([0, 1000 - rail_bar, 0]) rail_run(1000);
    translate([1000, 0, 0]) rotate([0, 0, 90]) rail_run(1000);
}

// Flight 2 Railings
translate([p2_x, -1000, p2_z]) rotate([0, 0, -90]) translate([0, 0, main_h + ipe_thick]) {
    stair_rail(0);
    stair_rail(step_w - rail_bar);
}