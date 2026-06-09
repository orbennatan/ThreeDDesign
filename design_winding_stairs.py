"""
Design + validate a compact winding (spiral) stair path for
models/deck_only - Copy.scad.

Local stair coordinates (matching the .scad header):
    local x = east/west, EAST is NEGATIVE
    local y = north/south, SOUTH is NEGATIVE
A stair_path point is [local_x, local_y].

Goal:
    - Keep winding all the way down (continuous turning spiral).
    - Minimise east reach (keep local_x as close to 0 / least negative).
    - NEVER let any tread footprint overlap a wall leg.

Walls (full height, so plan-overlap == penetration):
    Leg A (N-S): x in [0, 150],     y in [-1640, 0]
    Leg B (E-W): x in [-1100, 0],   y in [-1640, -1790]
"""

import math

# --- fixed stair params (from the .scad) ---
STAIR_WIDTH = 1000.0
STAIR_GOING = 300.0
STAIR_RISERS = 14            # -> 15 path points, 14 segments
N_POINTS = STAIR_RISERS + 1
HALF_W = STAIR_WIDTH / 2.0
HALF_G = STAIR_GOING / 2.0

# Deck connection: top of stair should start near here.
P0_TARGET = (-580.0, 0.0)

# --- walls as axis-aligned rectangles [xmin, xmax, ymin, ymax] ---
WALLS = [
    (0.0, 150.0, -1640.0, 0.0),       # leg A
    (-1100.0, 0.0, -1790.0, -1640.0), # leg B
]
WALL_MARGIN = 25.0  # keep a small clearance from the walls


def expand(rect, m):
    x0, x1, y0, y1 = rect
    return (x0 - m, x1 + m, y0 - m, y1 + m)


WALLS_M = [expand(w, WALL_MARGIN) for w in WALLS]


def point_in_rect(px, py, rect):
    x0, x1, y0, y1 = rect
    return x0 <= px <= x1 and y0 <= py <= y1


def tread_corners(p_prev, p_cur):
    mx = (p_prev[0] + p_cur[0]) / 2.0
    my = (p_prev[1] + p_cur[1]) / 2.0
    dx = p_cur[0] - p_prev[0]
    dy = p_cur[1] - p_prev[1]
    L = math.hypot(dx, dy) or 1.0
    ux, uy = dx / L, dy / L          # along path
    nx, ny = -uy, ux                 # perpendicular (tread width dir)
    corners = []
    for sg in (-HALF_G, HALF_G):
        for sw in (-HALF_W, HALF_W):
            corners.append((mx + ux * sg + nx * sw,
                            my + uy * sg + ny * sw))
    return corners


def tread_hits_wall(p_prev, p_cur):
    corners = tread_corners(p_prev, p_cur)
    # sample the perimeter densely so edges that cross a wall are caught
    samples = []
    for i in range(len(corners)):
        a = corners[i]
        b = corners[(i + 1) % len(corners)]
        for t in [k / 8.0 for k in range(9)]:
            samples.append((a[0] + (b[0] - a[0]) * t,
                            a[1] + (b[1] - a[1]) * t))
    samples.extend(corners)
    for sx, sy in samples:
        for w in WALLS_M:
            if point_in_rect(sx, sy, w):
                return True
    return False


def _ordered_quad(corners):
    # tread_corners returns [(-g,-w),(-g,+w),(+g,-w),(+g,+w)]; reorder to a loop
    return [corners[0], corners[1], corners[3], corners[2]]


def _sat_overlap(poly_a, poly_b):
    """Separating Axis Theorem for two convex quads (treads)."""
    for poly in (poly_a, poly_b):
        n = len(poly)
        for i in range(n):
            x1, y1 = poly[i]
            x2, y2 = poly[(i + 1) % n]
            ax, ay = -(y2 - y1), (x2 - x1)  # edge normal
            amin = min((ax * px + ay * py) for px, py in poly_a)
            amax = max((ax * px + ay * py) for px, py in poly_a)
            bmin = min((ax * px + ay * py) for px, py in poly_b)
            bmax = max((ax * px + ay * py) for px, py in poly_b)
            if amax < bmin or bmax < amin:
                return False  # separating axis found -> no overlap
    return True


# Min riser gap that still leaves >= ~2000 mm headroom between stacked
# treads. rise ~= 166.4 mm, so 12 risers -> ~1997 mm. A winding stair is
# allowed to converge at the newel; only treads that stack with too little
# vertical clearance are a problem.
HEADROOM_GAP = 12


def has_self_overlap(pts):
    """Flag plan overlap only between treads that are fewer than HEADROOM_GAP
    risers apart (i.e. too little headroom). Treads a full loop apart may
    overlap at the newel, which is normal for a winding stair."""
    quads = []
    for i in range(1, len(pts)):
        quads.append(_ordered_quad(tread_corners(pts[i - 1], pts[i])))
    for i in range(len(quads)):
        for j in range(i + 2, len(quads)):  # skip adjacent treads
            if j - i >= HEADROOM_GAP:
                continue  # enough vertical separation -> overlap is OK
            if _sat_overlap(quads[i], quads[j]):
                return True
    return False


def evaluate(pts):
    """Return (ok, east_reach) where east_reach = min local_x of any corner."""
    ok = True
    east = 0.0
    for i in range(1, len(pts)):
        if tread_hits_wall(pts[i - 1], pts[i]):
            ok = False
        for c in tread_corners(pts[i - 1], pts[i]):
            east = min(east, c[0])
    return ok, east


def build_spiral(cx, cy, R0, dR, theta0, direction):
    """A winding stair as a (possibly tapering) spiral about (cx, cy).
    Steps along the walking line by STAIR_GOING each riser."""
    pts = []
    th = theta0
    R = R0
    for _i in range(N_POINTS):
        pts.append((cx + R * math.cos(th), cy + R * math.sin(th)))
        Rmid = max(R + dR / 2.0, 200.0)
        th += direction * (STAIR_GOING / Rmid)
        R = max(R + dR, 200.0)
    return pts


def build_arc(cx, cy, R, theta0, dtheta):
    """A constant-radius circular arc about (cx, cy), one tread per step."""
    return [(cx + R * math.cos(theta0 + i * dtheta),
             cy + R * math.sin(theta0 + i * dtheta))
            for i in range(N_POINTS)]


# A 270 deg turn over 14 equal chords of STAIR_GOING fixes the radius:
#   chord = 2 R sin(sweep / (2 * n_segments))
SWEEP_DEG = 270.0
N_SEG = N_POINTS - 1                      # 14
DTHETA = math.radians(SWEEP_DEG / N_SEG)  # per-step turn (magnitude)
ARC_R = STAIR_GOING / (2.0 * math.sin(DTHETA / 2.0))


def total_turn_deg(cx, cy, pts):
    tot = 0.0
    for k in range(1, len(pts)):
        a0 = math.atan2(pts[k - 1][1] - cy, pts[k - 1][0] - cx)
        a1 = math.atan2(pts[k][1] - cy, pts[k][0] - cx)
        da = (a1 - a0 + math.pi) % (2 * math.pi) - math.pi
        tot += da
    return abs(math.degrees(tot))


# Floor rules (per user): the slab may be extended as far NORTH (+y) as
# needed, and treads MAY cross into positive y. The southern slab edge is
# fixed, so treads must stay north of it.
SOUTH_LIMIT = -1900.0   # do not run off the south edge of the existing slab
WEST_LIMIT = -4500.0    # keep within the slab to the west


def search_north_ending(target_deg, tol=8.0):
    """Find the LEAST-east winding spiral that:
        - connects to the deck at P0_TARGET,
        - descends south first (away from the deck),
        - turns ~target_deg total,
        - finishes with the bottom tread heading NORTH (+y),
        - never touches a wall, stays on the slab (south/west), north free.
    Returns (east, cx, cy, R0, dR, direction, turn, pts) or None.
    """
    best = None
    p0x, p0y = P0_TARGET
    for icx in range(-2600, 401, 10):
        cx = float(icx)
        for icy in range(-2600, 1201, 10):
            cy = float(icy)
            R0 = math.hypot(p0x - cx, p0y - cy)
            if R0 < 450.0 or R0 > 2600.0:
                continue
            theta0 = math.atan2(p0y - cy, p0x - cx)
            for dRi in range(-150, 61, 10):
                dR = float(dRi)
                for direction in (+1, -1):
                    pts = build_spiral(cx, cy, R0, dR, theta0, direction)
                    if math.hypot(pts[0][0] - p0x, pts[0][1] - p0y) > 5:
                        continue
                    # descend south first (leave the deck)
                    if pts[1][1] - pts[0][1] > 40:
                        continue
                    if abs(total_turn_deg(cx, cy, pts) - target_deg) > tol:
                        continue
                    # bottom tread heads north
                    dx = pts[-1][0] - pts[-2][0]
                    dy = pts[-1][1] - pts[-2][1]
                    L = math.hypot(dx, dy) or 1.0
                    if dy / L < 0.90:
                        continue
                    cornx, corny = [], []
                    for k in range(1, len(pts)):
                        for c in tread_corners(pts[k - 1], pts[k]):
                            cornx.append(c[0]); corny.append(c[1])
                    if (min(corny) < SOUTH_LIMIT or
                            min(cornx) < WEST_LIMIT or max(cornx) > 400):
                        continue
                    if any(tread_hits_wall(pts[k - 1], pts[k])
                           for k in range(1, len(pts))):
                        continue
                    east = min(cornx)
                    turn = total_turn_deg(cx, cy, pts)
                    if best is None or east > best[0]:
                        best = (east, cx, cy, R0, dR, direction, turn, pts)
    return best


def _report(label, best):
    if best is None:
        print(f"{label}: no feasible north-ending stair.")
        return
    east, cx, cy, R0, dR, direction, turn, pts = best
    cornx = [c[0] for k in range(1, len(pts))
             for c in tread_corners(pts[k - 1], pts[k])]
    corny = [c[1] for k in range(1, len(pts))
             for c in tread_corners(pts[k - 1], pts[k])]
    print(f"{label}: east={east:.0f}  turn={turn:.0f}deg  "
          f"south={min(corny):.0f}  north={max(corny):.0f}  "
          f"end={pts[-1][0]:.0f},{pts[-1][1]:.0f}")
    print("  stair_path = [")
    for p in pts:
        print(f"      [{p[0]:.0f}, {p[1]:.0f}],")
    print("  ];")


def build_twoarc(n1, t1, t2, h0_deg=-90.0, p0=P0_TARGET):
    """Two constant-curvature arcs joined: n1 steps turning t1 deg/step, then
    the rest turning t2 deg/step. Starts at p0 heading h0 (due SOUTH)."""
    pts = [p0]
    h = math.radians(h0_deg)
    x, y = p0
    for j in range(N_POINTS - 1):
        x += STAIR_GOING * math.cos(h)
        y += STAIR_GOING * math.sin(h)
        pts.append((x, y))
        h += math.radians(t1 if j < n1 else t2)
    return pts


def single_valley(pts):
    """True if y decreases (south) to one apex then increases (north)."""
    ys = [p[1] for p in pts]
    apex = ys.index(min(ys))
    for i in range(1, apex + 1):
        if ys[i] > ys[i - 1] + 1e-6:
            return False
    for i in range(apex + 1, len(ys)):
        if ys[i] < ys[i - 1] - 1e-6:
            return False
    return apex


def seg_heading(pts, i):
    dx = pts[i + 1][0] - pts[i][0]
    dy = pts[i + 1][1] - pts[i][1]
    return math.degrees(math.atan2(dy, dx))


# The named waypoint: the east tip of the E-W wall (leg B).
WALL_TIP = (-1100.0, -1640.0)


def search_corner():
    """Find the deck-to-floor winding line that:
        - starts at the deck heading due SOUTH,
        - dives down in a single clean valley and rounds the EAST TIP of the
          E-W wall (WALL_TIP), reaching close to the south wall,
        - keeps curving to finish with the bottom tread heading NORTH,
        - never penetrates either wall, stays on the slab.
    Two-arc curvature family: n1 steps at t1 deg/step, rest at t2 deg/step.
    Ranked by how close the southern apex gets to WALL_TIP.
    """
    best = None
    for n1 in range(4, 11):
        t1 = -22.0
        while t1 <= 0.01:
            t2 = -32.0
            while t2 <= -2.0:
                pts = build_twoarc(n1, t1, t2)
                # must end heading north (last segment ~ +90 deg)
                hend = seg_heading(pts, N_POINTS - 2)
                if abs(hend - 90.0) > 8.0:
                    t2 += 0.5
                    continue
                apex = single_valley(pts)
                if apex is False or apex < 3 or apex > 11:
                    t2 += 0.5
                    continue
                apex_pt = pts[apex]
                cornx, corny = [], []
                for k in range(1, len(pts)):
                    for c in tread_corners(pts[k - 1], pts[k]):
                        cornx.append(c[0]); corny.append(c[1])
                if (min(corny) < SOUTH_LIMIT or min(cornx) < WEST_LIMIT or
                        max(cornx) > 400):
                    t2 += 0.5
                    continue
                if any(tread_hits_wall(pts[k - 1], pts[k])
                       for k in range(1, len(pts))):
                    t2 += 0.5
                    continue
                south = min(corny)
                # rank: push the centerline APEX down to the wall (y=-1640)
                # and near the tip's x-standoff, then minimise west bulge.
                apex_gap = abs(apex_pt[1] - (-1640.0))
                score = (round(apex_gap / 25.0), -min(cornx))
                tip_dist = math.hypot(apex_pt[0] - WALL_TIP[0],
                                      apex_pt[1] - WALL_TIP[1])
                if best is None or score < best[0]:
                    best = (score, n1, t1, t2, apex, apex_pt,
                            south, max(corny), hend, tip_dist, pts)
                t2 += 0.5
            t1 += 1.0
    return best


def build_threearc(n1, t1, n2, t2, t3, h0_deg=-90.0, p0=P0_TARGET):
    """Three constant-curvature phases joined into one walking line:
        phase 1: n1 steps turning t1 deg/step  (slow descent, gain depth)
        phase 2: n2 steps turning t2 deg/step  (sharp bottom whip to due-east)
        phase 3: the rest turning t3 deg/step   (curl up to finish north)
    Starts at p0 heading h0 (due SOUTH)."""
    pts = [p0]
    h = math.radians(h0_deg)
    x, y = p0
    for j in range(N_POINTS - 1):
        x += STAIR_GOING * math.cos(h)
        y += STAIR_GOING * math.sin(h)
        pts.append((x, y))
        if j < n1:
            h += math.radians(t1)
        elif j < n1 + n2:
            h += math.radians(t2)
        else:
            h += math.radians(t3)
    return pts


def search_apex_on_wall():
    """Three-arc search that drives the CENTERLINE apex down onto the south
    wall latitude (y ~ -1640) just west of the tip, then finishes facing
    NORTH. Ranked by apex depth (closest to the wall), then least west bulge.
    """
    best = None
    for n1 in range(1, 6):
        for n2 in range(2, 7):
            if n1 + n2 >= N_POINTS - 2:
                continue
            t1 = 0.0
            while t1 >= -16.01:
                t2 = -6.0
                while t2 >= -34.01:
                    t3 = -6.0
                    while t3 >= -34.01:
                        pts = build_threearc(n1, t1, n2, t2, t3)
                        hend = seg_heading(pts, N_POINTS - 2)
                        if abs(hend - 90.0) > 8.0:
                            t3 -= 1.0
                            continue
                        apex = single_valley(pts)
                        if apex is False or apex < 3 or apex > 11:
                            t3 -= 1.0
                            continue
                        apex_pt = pts[apex]
                        cornx, corny = [], []
                        for k in range(1, len(pts)):
                            for c in tread_corners(pts[k - 1], pts[k]):
                                cornx.append(c[0]); corny.append(c[1])
                        if (min(corny) < SOUTH_LIMIT or
                                min(cornx) < WEST_LIMIT or max(cornx) > 400):
                            t3 -= 1.0
                            continue
                        if any(tread_hits_wall(pts[k - 1], pts[k])
                               for k in range(1, len(pts))):
                            t3 -= 1.0
                            continue
                        if has_self_overlap(pts):
                            t3 -= 1.0
                            continue
                        # West bulge is acceptable. Rank by getting the
                        # deepest tread (south corner) down beside the wall
                        # (toward the wall's south face at -1790), without
                        # running off the slab edge (-1900).
                        deep = min(corny)
                        score = (round(abs(deep - (-1790.0)) / 20.0),)
                        if best is None or score < best[0]:
                            best = (score, n1, t1, n2, t2, t3,
                                    apex, apex_pt, min(corny), max(corny),
                                    hend, pts)
                        t3 -= 1.0
                    t2 -= 1.0
                t1 -= 1.0
    return best


def main():
    print("=== Deck -> south -> APEX ON WALL -> north (3-arc) ===")
    print(f"  wall tip = {WALL_TIP}")
    best = search_apex_on_wall()
    if best is None:
        print("No feasible apex-on-wall path found.")
        return
    (score, n1, t1, n2, t2, t3, apex, apex_pt,
     south, north, hend, pts) = best
    n3 = N_POINTS - 1 - n1 - n2
    print(f"  arcs: {n1}@{t1:.0f} | {n2}@{t2:.0f} | {n3}@{t3:.0f} deg/step")
    print(f"  apex(step {apex}) at ({apex_pt[0]:.0f},{apex_pt[1]:.0f})  "
          f"centerline gap to wall(-1640)={abs(apex_pt[1]+1640):.0f}mm")
    print(f"  south corner={south:.0f} (wall at -1640)  north reach={north:.0f}")
    print(f"  last-tread heading={hend:.0f}deg (north=+90)")
    print(f"  east/west reach(min x)={min(p[0] for p in pts):.0f}")
    print("stair_path = [")
    for p in pts:
        print(f"    [{p[0]:.0f}, {p[1]:.0f}],")
    print("];")


if __name__ == "__main__":
    main()
