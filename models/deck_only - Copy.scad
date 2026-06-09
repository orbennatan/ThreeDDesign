// --- REVISED DECK: IMPROVED STRUCTURAL VERSION ---
// Closer to Israeli residential engineering practice
// Main upgrades:
// - Larger primary beams
// - Stronger transverse members
// - Stronger support posts
// - Stronger railing posts
// - Reduced joist spacing
// - Added diagonal bracing
// - Added railing gussets

show_labels = true;
$fn = 64;

// =====================================================
// 1. MATERIAL GRADES & PROFILES
// =====================================================

// Primary longitudinal beams
main_h = 100;
main_w = 50;
main_wall = 4.0;

// Truss longbeams for the two east-most beam lines
truss_beam_count = 2;
truss_depth = 600;
truss_chord_h = 50;
truss_chord_wall = 4.0;
truss_web_w = 30;
truss_web_d = 26;
truss_panel_target = 700;

// Transverse members
lat_h  = 60;
lat_w  = 40;
lat_wall = 3.0;

// Support posts
pole_h = 60;
pole_w = 60;
pole_wall = 4.0;

// Decking
ipe_thick = 20;
ipe_w = 140;
ipe_gap = 1;

// Base plates
plate_w = 180;
plate_d = 180;
plate_thick = 10;

level_bolt_d = 16;
level_bolt_h = 120;

// Concrete wall bearing points at beam ends
wall_support_l = 260;
wall_support_w = 220;

// Railing posts
rpost_w = 50;
rpost_h = 50;
rpost_wall = 3.0;

// Railing gussets
gusset_t = 6;
gusset_l = 120;

// =====================================================
// 2. DECK DIMENSIONS
// =====================================================

deck_len = 5950;

// Original west edge stays fixed. The deck is extended 1 m east.
original_deck_wid = 3040;
east_extension = 1000;
deck_wid = original_deck_wid + east_extension;
east_y = -east_extension;
west_y = original_deck_wid;

deck_elev = 2380;

// Longbeams are about 2.0 m center-to-center across the expanded width.
longbar_ys = [
    east_y,
    east_y + (deck_wid - main_w) / 2,
    west_y - main_w
];

longbar_reductions = [
    0,
    1212,
    1610
];

longbar_count = len(longbar_ys);

function rock_height_at_y(y) =
    min(deck_elev - 180, max(0, (y / west_y) * (deck_elev - 180)));

// Reduced transverse spacing
bar_spacing = 320;

lat_count = ceil((deck_len - main_w) / bar_spacing) + 1;
lat_spacing = (deck_len - main_w) / (lat_count - 1);

// =====================================================
// 3. STAIR & SITE CONSTRAINTS
// =====================================================

// Site coordinates are local to the stair opening:
// local x = east/west, with east negative; local y = north/south, with south negative.
// They map into this model as [model_x, model_y] = [local_y, local_x].
stair_width = 1000;
stair_drop = 2330;
stair_risers = 14;
stair_visible_treads = stair_risers - 1;
stair_rise = stair_drop / stair_risers;
stair_going = 300;

stair_top_z = deck_elev + main_h + lat_h + ipe_thick;
stair_floor_z = stair_top_z - stair_drop;

stair_design_live_load_kg_m2 = 500;
stair_dynamic_factor = 1.5;
stair_stringer_w = 80;
stair_stringer_drop = 140;
stair_cross_h = 60;
stair_cross_w = 50;
stair_cross_wall = 4.0;
stair_support_spacing = 4;
stair_wall_clearance = 80;

site_wall_y = -1640;
site_wall_x = -1100;
site_wall_thick = 150;
site_wall_top_z = stair_top_z;

// Walking-line points, in the local stair coordinate system.
// 180-degree winding (south -> north) stair: leaves the deck heading due
// SOUTH, dives down in a single clean valley and rounds the EAST TIP of the
// E-W wall (leg B, tip at local (-1100,-1640)), bringing the treads down
// beside the south wall (south tread corner reaches ~-1747, past the -1640
// wall face), then keeps curving another ~90 degrees to finish with the
// bottom (lowest) tread heading NORTH (+y). The U bulges west to ~-3104 to
// keep the 1 m-wide treads clear of the wall tip while diving south - a
// tread tucked any closer would penetrate leg B. The floor is assumed
// extended north as needed; treads may cross into positive y. No tread
// footprint overlaps either wall leg (verified by design_winding_stairs.py).
stair_path = [
    [-stair_width/2 - stair_wall_clearance, 0],
    [-580, -300],
    [-663, -588],
    [-826, -840],
    [-1056, -1033],
    [-1323, -1169],
    [-1614, -1242],
    [-1914, -1247],
    [-2208, -1184],
    [-2480, -1058],
    [-2716, -873],
    [-2905, -640],
    [-3036, -370],
    [-3104, -78],
    [-3104, 222]
];

// Tread orientations are derived from the path itself (see
// stair_segment_angle below), so no hand-tuned angle table is needed.

// =====================================================
// 4. MODULES
// =====================================================

// RHS along X
module steel_rhs(l, w, h, wall) {
    difference() {
        color("SlateGray")
            cube([l, w, h]);

        translate([-1, wall, wall])
            cube([l + 2, w - 2*wall, h - 2*wall]);
    }
}

// RHS along Y
module steel_rhs_y(w, l, h, wall) {
    difference() {
        color("SlateGray")
            cube([w, l, h]);

        translate([wall, -1, wall])
            cube([w - 2*wall, l + 2, h - 2*wall]);
    }
}

// Centered solid web member used inside the truss longbeams
module truss_web_between(x1, z1, x2, z2) {

    color("DimGray")
        hull() {

            translate([
                x1 - truss_web_w/2,
                main_w/2 - truss_web_d/2,
                z1 - truss_web_w/2
            ])
                cube([truss_web_w, truss_web_d, truss_web_w]);

            translate([
                x2 - truss_web_w/2,
                main_w/2 - truss_web_d/2,
                z2 - truss_web_w/2
            ])
                cube([truss_web_w, truss_web_d, truss_web_w]);
        }
}

module truss_vertical_web(x) {

    translate([
        x - truss_web_w/2,
        main_w/2 - truss_web_d/2,
        main_h - truss_depth + truss_chord_h
    ])
        color("DimGray")
            cube([
                truss_web_w,
                truss_web_d,
                truss_depth - 2*truss_chord_h
            ]);
}

// Truss along X. Top chord remains level with the old beam top so lats still fit.
module truss_longbeam(l) {

    translate([0, 0, main_h - truss_depth])
        steel_rhs(l, main_w, truss_chord_h, truss_chord_wall);

    translate([0, 0, main_h - truss_chord_h])
        steel_rhs(l, main_w, truss_chord_h, truss_chord_wall);

    n_panels = ceil(l / truss_panel_target);
    panel_l = l / n_panels;

    bottom_z = main_h - truss_depth + truss_chord_h + truss_web_w/2;
    top_z = main_h - truss_chord_h - truss_web_w/2;

    for (p = [0:n_panels]) {

        x_node =
            min(
                l - truss_web_w/2,
                max(truss_web_w/2, p * panel_l)
            );

        truss_vertical_web(x_node);
    }

    for (p = [0:n_panels-1]) {

        x1 = p * panel_l + truss_web_w/2;
        x2 = (p + 1) * panel_l - truss_web_w/2;

        if (p % 2 == 0)
            truss_web_between(x1, bottom_z, x2, top_z);
        else
            truss_web_between(x1, top_z, x2, bottom_z);
    }
}

// Hollow support post
module flush_pole(h, w_match, h_match) {
    difference() {
        color("DimGray")
            cube([h_match, w_match, h]);

        translate([pole_wall, pole_wall, -1])
            cube([
                h_match - 2*pole_wall,
                w_match - 2*pole_wall,
                h + 2
            ]);
    }
}

// Base plate
module leveling_plate() {

    color("DarkSlateGray")
        cube([plate_w, plate_d, plate_thick]);

    color("Black") {

        for (x = [25, plate_w - 25])
        for (y = [25, plate_d - 25])

            translate([x, y, plate_thick])
                cylinder(
                    h = level_bolt_h,
                    d = level_bolt_d
                );
    }
}

// Adjustable support
module adjustable_rock_support(h) {

    translate([
        -plate_w/2 + pole_w/2,
        -plate_d/2 + pole_w/2,
        0
    ])
        leveling_plate();

    translate([0, 0, plate_thick])
        flush_pole(
            h - plate_thick,
            pole_w,
            pole_w
        );
}

// Concrete wall support under a beam end
module concrete_wall_support(h) {

    color("Gainsboro")
        cube([wall_support_l, wall_support_w, h]);
}

// Structural railing post
module structural_rail_post(post_height = 1160) {

    color("DarkSlateGray")
    difference() {

        cube([rpost_w, rpost_h, post_height]);

        translate([
            rpost_wall,
            rpost_wall,
            -1
        ])
            cube([
                rpost_w - 2*rpost_wall,
                rpost_h - 2*rpost_wall,
                post_height + 2
            ]);
    }
}

// Triangular railing gusset
module railing_gusset() {

    color("DimGray")

    linear_extrude(height = gusset_t)

        polygon([
            [0,0],
            [gusset_l,0],
            [0,gusset_l]
        ]);
}

// Top rail tube
top_d = 30;
top_wall = 2;

module top_tube(L) {

    rotate([0,90,0])

    difference() {

        cylinder(h = L, d = top_d);

        translate([0,0,-1])
            cylinder(
                h = L + 2,
                d = top_d - 2*top_wall
            );
    }
}

function stair_global_xy(p) = [p[1], p[0]];
function stair_level_z(i) = stair_top_z - i * stair_rise;
function stair_segment_len(i) =
    let(
        p0 = stair_path[i],
        p1 = stair_path[i + 1],
        dx = p1[0] - p0[0],
        dy = p1[1] - p0[1]
    )
    sqrt(dx*dx + dy*dy);

// Angle (deg) of each segment in MODEL space. The global mapping swaps
// axes (model = [local_y, local_x]), so the tread rotation about Z is
// atan2(dx_local, dy_local).
function stair_segment_angle(i) =
    let(
        p0 = stair_path[i],
        p1 = stair_path[i + 1],
        dx = p1[0] - p0[0],
        dy = p1[1] - p0[1]
    )
    atan2(dx, dy);

function stair_segment_normal(i) =
    let(
        p0 = stair_path[i],
        p1 = stair_path[i + 1],
        dx = p1[0] - p0[0],
        dy = p1[1] - p0[1],
        L = stair_segment_len(i)
    )
    [-dy / L, dx / L];

function stair_offset_point(i, p, off) =
    let(n = stair_segment_normal(i))
    [p[0] + n[0] * off, p[1] + n[1] * off];

function stair_midpoint(i) =
    [
        (stair_path[i - 1][0] + stair_path[i][0]) / 2,
        (stair_path[i - 1][1] + stair_path[i][1]) / 2
    ];

function stair_node_offset_point(i, off) =
    stair_offset_point(
        min(stair_risers - 1, max(0, i)),
        stair_path[i],
        off
    );

module solid_member_between(p0, z0, p1, z1, size, c = "SlateGray") {

    g0 = stair_global_xy(p0);
    g1 = stair_global_xy(p1);

    color(c)
        hull() {

            translate([
                g0[0] - size/2,
                g0[1] - size/2,
                z0 - size/2
            ])
                cube([size, size, size]);

            translate([
                g1[0] - size/2,
                g1[1] - size/2,
                z1 - size/2
            ])
                cube([size, size, size]);
        }
}

module local_xy_cube(x0, y0, z0, dx, dy, dz) {

    translate([y0, x0, z0])
        cube([dy, dx, dz]);
}

module stair_tread(i) {

    p = stair_midpoint(i);
    g = stair_global_xy(p);
    a = stair_segment_angle(i - 1);
    z = stair_level_z(i);

    translate([g[0], g[1], z]) {

        rotate([0, 0, a]) {

            translate([
                -stair_going/2,
                -stair_width/2,
                -ipe_thick
            ])
                color("SaddleBrown")
                    cube([stair_going, stair_width, ipe_thick]);

            translate([
                -stair_going/2,
                -stair_width/2,
                -ipe_thick - stair_cross_h
            ])
                steel_rhs_y(
                    stair_cross_w,
                    stair_width,
                    stair_cross_h,
                    stair_cross_wall
                );

            translate([
                stair_going/2 - stair_cross_w,
                -stair_width/2,
                -ipe_thick - stair_cross_h
            ])
                steel_rhs_y(
                    stair_cross_w,
                    stair_width,
                    stair_cross_h,
                    stair_cross_wall
                );
        }
    }
}

module curved_stair_stringers() {

    stringer_offsets = [
        -stair_width/2 + stair_stringer_w/2,
        0,
        stair_width/2 - stair_stringer_w/2
    ];

    for (seg = [0:stair_risers-1])
    for (off = stringer_offsets) {

        p0 = stair_offset_point(seg, stair_path[seg], off);
        p1 = stair_offset_point(seg, stair_path[seg + 1], off);

        solid_member_between(
            p0,
            stair_level_z(seg) - ipe_thick - stair_stringer_drop,
            p1,
            stair_level_z(seg + 1) - ipe_thick - stair_stringer_drop,
            stair_stringer_w
        );
    }
}

module curved_stair_supports() {

    support_offsets = [
        -stair_width/2 + stair_stringer_w/2,
        0,
        stair_width/2 - stair_stringer_w/2
    ];

    for (node = [stair_support_spacing:stair_support_spacing:stair_visible_treads])
    for (off = support_offsets) {

        p = stair_node_offset_point(node, off);
        g = stair_global_xy(p);
        z_top = stair_level_z(node) - ipe_thick - stair_stringer_drop;
        h = z_top - stair_floor_z;

        if (h > plate_thick + 100)
            translate([
                g[0] - pole_w/2,
                g[1] - pole_w/2,
                stair_floor_z
            ])
                adjustable_rock_support(h);
    }
}

module stair_rail_posts_and_top(offset) {

    rail_nodes = [0, 3, 6, 9, 12, 14];

    for (i = rail_nodes) {

        p = stair_node_offset_point(i, offset);
        g = stair_global_xy(p);

        translate([
            g[0] - rpost_w/2,
            g[1] - rpost_h/2,
            stair_level_z(i)
        ])
            structural_rail_post(rail_h);
    }

    for (j = [0:len(rail_nodes)-2]) {

        i0 = rail_nodes[j];
        i1 = rail_nodes[j + 1];

        p0 = stair_node_offset_point(i0, offset);
        p1 = stair_node_offset_point(i1, offset);

        solid_member_between(
            p0,
            stair_level_z(i0) + rail_h - top_d/2,
            p1,
            stair_level_z(i1) + rail_h - top_d/2,
            top_d,
            "DimGray"
        );
    }
}

module curved_stair_rails() {

    stair_rail_posts_and_top(-stair_width/2);
    stair_rail_posts_and_top(stair_width/2);
}

module site_reference_geometry() {

    wall_h = site_wall_top_z - stair_floor_z;

    color([0.78, 0.78, 0.72, 0.45]) {

        // Solid floor at the bottom of the stair.
        local_xy_cube(
            -4600,
            -1900,
            stair_floor_z - 60,
            5000,
            2500,
            60
        );

        // Wall from the stair origin southward to y = -1640 mm.
        local_xy_cube(
            0,
            site_wall_y,
            stair_floor_z,
            site_wall_thick,
            -site_wall_y,
            wall_h
        );

        // Wall from y = -1640 mm eastward to x = -1100 mm.
        local_xy_cube(
            site_wall_x,
            site_wall_y - site_wall_thick,
            stair_floor_z,
            -site_wall_x,
            site_wall_thick,
            wall_h
        );
    }
}

module curved_staircase() {

    site_reference_geometry();

    curved_stair_stringers();

    for (i = [1:stair_visible_treads])
        stair_tread(i);

    curved_stair_supports();
    curved_stair_rails();
}

// =====================================================
// 5. MAIN DECK FRAME
// =====================================================

translate([0,0,deck_elev]) {

    difference() {

        union() {

            // Primary beams

            for (i = [0:longbar_count-1]) {

                y = longbar_ys[i];
                x_start = longbar_reductions[i];

                translate([x_start, y, 0]) {

                    if (i < truss_beam_count)
                        truss_longbeam(deck_len - x_start);
                    else
                        steel_rhs(
                            deck_len - x_start,
                            main_w,
                            main_h,
                            main_wall
                        );
                }
            }

            // Transverse members

            for (i = [0:lat_count-1]) {

                x = i * lat_spacing;

                translate([x,east_y,main_h])

                    steel_rhs_y(
                        lat_w,
                        deck_wid,
                        lat_h,
                        lat_wall
                    );
            }

            // Ipe decking

            for (y = [east_y:ipe_w + ipe_gap:west_y - ipe_w])

                translate([0, y, main_h + lat_h])

                    color("SaddleBrown")
                        cube([
                            deck_len,
                            ipe_w,
                            ipe_thick
                        ]);
        }

        // Curved south cutout

        translate([0,0,main_h - truss_depth - 20])

        linear_extrude(
            truss_depth + lat_h + ipe_thick + 40
        )

        polygon([
            [-200,east_y - 200],
            [-200,west_y + 200],
            [1610,west_y + 200],
            [1610,west_y],
            [1610,2660],
            [1590,2280],
            [1540,1900],
            [1450,1520],
            [1300,1140],
            [1060,760],
            [740,380],
            [0,0],
            [0,east_y - 200]
        ]);
    }
}

// =====================================================
// 6. SUPPORTS
// =====================================================

for (i = [0:longbar_count-1]) {

    y = longbar_ys[i];
    rock_z = rock_height_at_y(y + main_w/2);
    support_h = deck_elev - rock_z;
    reduction = longbar_reductions[i];
    wall_h =
        i < truss_beam_count ?
            deck_elev + main_h - truss_depth - rock_z :
            support_h;

    // Concrete wall bearing at both beam ends.
    for (x_wall = [reduction, deck_len]) {

        translate([
            x_wall - wall_support_l/2,
            y + main_w/2 - wall_support_w/2,
            rock_z
        ])

        concrete_wall_support(wall_h);
    }

    if (i >= truss_beam_count) {
        for (s = [1:2]) {

            x_supp =
                reduction +
                s * (deck_len - reduction) / 3;

            translate([
                x_supp,
                y + main_w/2 - pole_w/2,
                rock_z
            ])

            adjustable_rock_support(support_h);
        }
    }
}


// =====================================================
// 7. CURVED STAIRCASE
// =====================================================

curved_staircase();


// =====================================================
// 8. RAILINGS
// =====================================================

rail_z0 = deck_elev + main_h;
rail_h  = 1100;

rail_bar = 10;
rail_gap = 90;
rail_pitch = rail_bar + rail_gap;

// East side posts

translate([0,east_y,rail_z0])
    structural_rail_post();

translate([deck_len/3 - rpost_w/2,east_y,rail_z0])
    structural_rail_post();

translate([2*deck_len/3 - rpost_w/2,east_y,rail_z0])
    structural_rail_post();

translate([deck_len - rpost_w,east_y,rail_z0])
    structural_rail_post();

// North side posts

translate([
    deck_len - rpost_w,
    east_y + deck_wid/2,
    rail_z0
])
    structural_rail_post();

translate([
    deck_len - rpost_w,
    west_y - rpost_h,
    rail_z0
])
    structural_rail_post();

// Gussets at corner post

translate([
    deck_len - rpost_w,
    east_y,
    rail_z0
])
rotate([90,0,0])
    railing_gusset();

translate([
    deck_len - rpost_w,
    east_y,
    rail_z0
])
rotate([90,0,90])
    railing_gusset();

// East railing infill

color("DimGray")

translate([0,east_y,rail_z0]) {

    n_e =
        floor((deck_len - rail_bar) / rail_pitch) + 1;

    off_e =
        (deck_len -
        (n_e * rail_bar +
        (n_e - 1) * rail_gap)) / 2;

    for (i = [0:n_e-1])

        translate([
            off_e + i * rail_pitch,
            0,
            0
        ])

        cube([
            rail_bar,
            rail_bar,
            rail_h
        ]);

    translate([
        0,
        rail_bar/2,
        rail_h - top_d/2
    ])

    top_tube(deck_len);
}

// North railing infill

color("DimGray")

translate([
    deck_len - rail_bar,
    east_y,
    rail_z0
]) {

    n_n =
        floor((deck_wid - rail_bar) / rail_pitch) + 1;

    off_n =
        (deck_wid -
        (n_n * rail_bar +
        (n_n - 1) * rail_gap)) / 2;

    for (i = [0:n_n-1])

        translate([
            0,
            off_n + i * rail_pitch,
            0
        ])

        cube([
            rail_bar,
            rail_bar,
            rail_h
        ]);

    translate([
        rail_bar/2,
        0,
        rail_h - top_d/2
    ])

    rotate([0,0,90])

        top_tube(deck_wid);
}

// =====================================================
// 9. LABELS
// =====================================================

if (show_labels) {

    label_size = 300;

    label_z =
        rail_z0 +
        rail_h +
        50;

    color("Red") {

        translate([
            deck_len/2,
            east_y - 600,
            label_z
        ])

        linear_extrude(2)
            text(
                "EAST",
                size = label_size,
                halign = "center"
            );

        translate([
            deck_len/2,
            west_y + 300,
            label_z
        ])

        linear_extrude(2)
            text(
                "WEST",
                size = label_size,
                halign = "center"
            );
    }
}
