// --- FULL DECK FRAME & PERFECTLY ALIGNED 2-STAGE STAIRS ---
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

// Recommended profiles for structural railing posts
rpost_w = 40; rpost_h = 40; rpost_wall = 3.0;

// --- 2. DECK DIMENSIONS ---
deck_len = 5950; deck_wid = 3040;
deck_elev = 2380;
bar_spacing = 380;
reductions = [0, 740, 1060, 1300, 1450, 1540, 1590, 1610, 1610];

// --- 3. STAIR SPECS ---
step_h = 170; step_tread = 280; step_w = 1000;
num_steps = 7;
stair_str_h    = 160;
stair_str_w    = 60;   
stair_str_wall = 4;
stair_slope_len = num_steps * sqrt(step_tread*step_tread + step_h*step_h);
stair_angle     = atan(step_h / step_tread);

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

// Dedicated structural post for railings
module structural_rail_post() {
    color("DarkSlateGray") difference() {
        cube([rpost_w, rpost_h, 1100]);
        translate([rpost_wall, rpost_wall, -1]) 
            cube([rpost_w - 2*rpost_wall, rpost_h - 2*rpost_wall, 1100 + 2]);
    }
}

// FIXED: Real frame for the landings including the Ipe wood planks on top
module podest_frame() {
    // Perimeter steel beams in X
    translate([0, 0, 0]) steel_rhs(1000, main_w, main_h, main_wall);
    translate([0, 1000 - main_w, 0]) steel_rhs(1000, main_w, main_h, main_wall);
    // Perimeter steel beams in Y
    translate([0, main_w, 0]) steel_rhs_y(main_w, 1000 - 2*main_w, main_h, main_wall);
    translate([1000 - main_w, main_w, 0]) steel_rhs_y(main_w, 1000 - 2*main_w, main_h, main_wall);
    // Center structural reinforcement beam
    translate([500 - main_w/2, main_w, 0]) steel_rhs_y(main_w, 1000 - 2*main_w, main_h, main_wall);

    // FIXED REGRESSION: Layering the Ipe wood planks back onto the landing frame surface
    for (y = [0 : ipe_w + ipe_gap : 1000 - ipe_w]) {
        translate([0, y, main_h]) color("SaddleBrown") cube([1000, ipe_w, ipe_thick]);
    }
}

// Stair flight with a central support stringer to prevent tread flexing
module stair_flight() {
    straight_stringer(); // Left
    translate([0, (step_w - stair_str_w)/2, 0]) straight_stringer(); // Center stringer
    translate([0, step_w - stair_str_w, 0]) straight_stringer(); // Right
    
    for (i = [0 : num_steps - 1]) {
        tread_top   = -i * step_h;
        z_str_front = -(i + 1) * step_h - ipe_thick;

        // Vertical support risers welded onto all 3 stringers
        translate([(i + 1) * step_tread - stair_str_w, 0, z_str_front])
            steel_rhs(stair_str_w, stair_str_w, step_h, stair_str_wall);
        translate([(i + 1) * step_tread - stair_str_w, (step_w - stair_str_w)/2, z_str_front])
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
            // 4 primary longbars running North-South (X axis)
            longbar_ys = [0, 1000, 2000, deck_wid - main_w];
            longbar_reductions = [0, 1212, 1553, 1610]; 
            
            for (i = [0 : 3]) {
                y = longbar_ys[i];
                x_start = longbar_reductions[i];
                translate([x_start, y, 0]) steel_rhs(deck_len - x_start, main_w, main_h, main_wall);
            }

            // Transverse Latitude Profiles running East-West (Y axis) on top of the longbars
            for (x = [0 : bar_spacing : deck_len - main_w]) {
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

// B. SUPPORT POLES & LATERAL BRACING
longbar_ys = [0, 1000, 2000, deck_wid - main_w];
longbar_reductions = [0, 1212, 1553, 1610];
for (i = [0 : 3]) {
    y = longbar_ys[i];
    for (s = [1 : 3]) {
        x_supp = s * deck_len / 4;
        reduction = longbar_reductions[i];
        if (x_supp > reduction) {
            translate([x_supp, y + main_w/2 - pole_w/2, 0]) flush_pole(deck_elev, pole_w, pole_w);
            
            // Cross-bracing between consecutive vertical posts
            if (s < 3) {
                x_next = (s + 1) * deck_len / 4;
                color("LightSlateGray") translate([x_supp, y + main_w/2, 200]) 
                    rotate([0, atan2(deck_elev - 400, x_next - x_supp), 0]) 
                        cube([sqrt(pow(x_next - x_supp, 2) + pow(deck_elev - 400, 2)), 4, 30]);
            }
        }
    }
}

// C. STAIRCASE SYSTEM
// 1. Upper Podest (100x100cm)
translate([0, -1000, deck_elev]) {
    podest_frame(); 
    // 2. Flight 1 (Slight adjustment to align with the new top of wood height)
    translate([1000, 0, main_h + ipe_thick]) stair_flight();
}

// 3. Lower Podest (100x100cm)
p2_x = 1000 + (num_steps * step_tread);
p2_z = deck_elev - (num_steps * step_h);

translate([p2_x, -1000, p2_z]) {
    podest_frame();
    // 4. Flight 2
    rotate([0, 0, -90]) translate([0, 0, main_h + ipe_thick]) stair_flight();
}

// 5. PODEST SUPPORT POSTS
translate([0,            -1000, 0]) flush_pole(deck_elev, main_w, pole_h);
translate([1000 - pole_h, -1000, 0]) flush_pole(deck_elev, main_w, pole_h);
translate([p2_x,                 -1000,    0]) flush_pole(p2_z, main_w, pole_h);
translate([p2_x + 1000 - pole_h, -1000,    0]) flush_pole(p2_z, main_w, pole_h);
translate([p2_x,                 -main_w,  0]) flush_pole(p2_z, main_w, pole_h);
translate([p2_x + 1000 - pole_h, -main_w,  0]) flush_pole(deck_elev, 2 * main_w, pole_h);

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

    beam_label_size = 200;
    beam_ys = [0, 1000, 2000, deck_wid - main_w];
    color("Yellow")
        for (i = [0 : len(beam_ys) - 1])
            translate([deck_len - 300, beam_ys[i] + main_w/2, label_z])
                linear_extrude(2) text(str(i + 1), size = beam_label_size, halign = "center", valign = "center");
}

// --- RAILINGS (North + East edges) ---
rail_h     = 1100;
rail_bar   = 10;
rail_gap   = 100;
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

// Structural post additions for perimeter railings
translate([0, 0, rail_z0]) structural_rail_post();
translate([deck_len/2, 0, rail_z0]) structural_rail_post();
translate([deck_len - rpost_w, 0, rail_z0]) structural_rail_post();
translate([deck_len - rpost_w, deck_wid/2, rail_z0]) structural_rail_post();
translate([deck_len - rpost_w, deck_wid - rpost_h, rail_z0]) structural_rail_post();

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

module rail_run(L) {
    color("DimGray") {
        n = floor((L - rail_bar) / rail_pitch) + 1;
        off = (L - (n * rail_bar + (n - 1) * rail_gap)) / 2;
        for (i = [0 : n - 1]) translate([off + i * rail_pitch, 0, 0]) cube([rail_bar, rail_bar, rail_h]);
        translate([0, rail_bar / 2, rail_h - top_d / 2]) top_tube(L);
    }
}

// --- STAIR / PODEST RAILINGS ---
// Corner structural posts for landing frames
translate([0, -1000, deck_elev + main_h + ipe_thick]) structural_rail_post();
translate([p2_x, -1000, p2_z + main_h + ipe_thick]) structural_rail_post();
translate([p2_x + 1000 - rpost_w, -1000, p2_z + main_h + ipe_thick]) structural_rail_post();

// Upper podest railing run
translate([0, -1000, deck_elev + main_h + ipe_thick]) {
    rail_run(1000);
    translate([rail_bar, 0, 0]) rotate([0, 0, 90]) rail_run(1000);
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

// Flight 1 Outer Rail
translate([0, -1000, deck_elev]) translate([1000, 0, main_h + ipe_thick]) stair_rail(0);

// Flight 1 Inner Gap Filler
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