"""
CAD Model Generator using CadQuery (OpenCascade).

Ported from: models/deck.scad
Deck with steel RHS frame, flush poles, rotated joists, and IPE wood decking.
All dimensions in mm.
"""

import os
import cadquery as cq
from cadquery import exporters
from OCP.BRepBuilderAPI import BRepBuilderAPI_MakeSolid
from OCP.TopExp import TopExp_Explorer
from OCP.TopAbs import TopAbs_SHELL

EXPORT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "exports")

# --- 1. MATERIAL GRADES (wall thickness) ---
main_wall  = 4.0
joist_wall = 3.0
pole_wall  = 4.0
ipe_thick  = 20.0

# --- 2. PROFILES ---
main_h  = 100;  main_w  = 50
joist_h = 80;   joist_w = 40
pole_h  = 100;  pole_w  = 50
ipe_w   = 140

# --- 3. DIMENSIONS ---
deck_len      = 5950
deck_wid      = 3000
deck_elev     = 1000
joist_spacing  = 400
ipe_gap        = 5


def ensure_solid(wp):
    """
    Ensure CadQuery result is a proper Solid (not a Compound of shells).
    Needed for proper STL export after boolean operations.
    """
    shape = wp.val()
    # If already a solid, return as-is
    if shape.ShapeType() == "Solid":
        return shape

    # Try to extract from compound
    if shape.ShapeType() == "Compound":
        solids = shape.Solids()
        if len(solids) == 1:
            return solids[0]
        elif len(solids) > 1:
            return shape  # Already compound of solids
        # If no solids, try to make one from shells
        explorer = TopExp_Explorer(shape.wrapped, TopAbs_SHELL)
        if explorer.More():
            builder = BRepBuilderAPI_MakeSolid()
            while explorer.More():
                from OCP.TopoDS import topods
                builder.Add(topods.Shell(explorer.Current()))
                explorer.Next()
            if builder.IsDone():
                return cq.Shape(builder.Solid())

    return shape


def make_rhs(length, width, height, wall):
    """
    Create an RHS (Rectangular Hollow Section) as a proper solid.
    Uses shell operation for accuracy.
    """
    wp = (
        cq.Workplane("XY")
        .box(length, width, height, centered=False)
        .faces(">X or <X")
        .shell(-wall)
    )
    return ensure_solid(wp)


def make_pole(height, width, depth, wall):
    """Create a hollow pole (closed all sides)."""
    outer = cq.Workplane("XY").box(depth, width, height, centered=False)
    inner = (
        cq.Workplane("XY")
        .transformed(offset=(wall, wall, wall))
        .box(depth - wall * 2, width - wall * 2, height - wall * 2, centered=False)
    )
    return ensure_solid(outer.cut(inner))


def make_board(length, width, height):
    """Simple solid board."""
    wp = cq.Workplane("XY").box(length, width, height, centered=False)
    return wp.val()


def move(shape, x=0, y=0, z=0):
    """Translate a shape."""
    return shape.moved(cq.Location(cq.Vector(x, y, z)))


def rotate_z_move(shape, angle, x=0, y=0, z=0):
    """Rotate about Z then translate."""
    s = shape.rotate((0, 0, 0), (0, 0, 1), angle)
    return s.moved(cq.Location(cq.Vector(x, y, z)))


def build_model():
    """Build the full deck — returns list of OCC shapes."""
    parts = []

    print("  Building perimeter frame...")
    # =========================================================
    # A. MAIN PERIMETER FRAME (at deck_elev)
    # =========================================================
    frame_beam = make_rhs(deck_len, main_w, main_h, main_wall)
    parts.append(move(frame_beam, 0, 0, deck_elev))
    parts.append(move(frame_beam, 0, deck_wid - main_w, deck_elev))

    side_beam = make_rhs(deck_wid, main_w, main_h, main_wall)
    parts.append(rotate_z_move(side_beam, 90, 0, 0, deck_elev))
    parts.append(rotate_z_move(side_beam, 90, deck_len, 0, deck_elev))

    print("  Building poles...")
    # =========================================================
    # B. FLUSH POLES (mid-span of each side)
    # =========================================================
    pole = make_pole(deck_elev, main_w, pole_h, pole_wall)
    parts.append(move(pole, deck_len / 2 - pole_h / 2, 0, 0))
    parts.append(move(pole, deck_len / 2 - pole_h / 2, deck_wid - main_w, 0))
    parts.append(rotate_z_move(pole, 90, 0, deck_wid / 2 - pole_h / 2, 0))
    parts.append(rotate_z_move(pole, 90, deck_len - main_w, deck_wid / 2 - pole_h / 2, 0))

    print("  Building joists...")
    # =========================================================
    # C. INTERNAL JOISTS
    # =========================================================
    joist_length = deck_len - main_w * 2
    joist_z = deck_elev + main_h - joist_h
    joist = make_rhs(joist_length, joist_w, joist_h, joist_wall)

    y = joist_spacing
    joist_count = 0
    while y < deck_wid - joist_spacing + 1:
        parts.append(move(joist, main_w, y, joist_z))
        y += joist_spacing
        joist_count += 1
    print(f"    {joist_count} joists")

    print("  Building decking boards...")
    # =========================================================
    # D. IPE DECKING BOARDS
    # =========================================================
    board_z = deck_elev + main_h
    board = make_board(ipe_w, deck_wid, ipe_thick)

    x = 0.0
    board_count = 0
    while x <= deck_len - ipe_w:
        parts.append(move(board, x, 0, board_z))
        x += ipe_w + ipe_gap
        board_count += 1
    print(f"    {board_count} boards")

    return parts


if __name__ == "__main__":
    print("Building deck model...")
    parts = build_model()
    print(f"  Total parts: {len(parts)}")

    os.makedirs(EXPORT_DIR, exist_ok=True)
    filepath = os.path.join(EXPORT_DIR, "model.stl")

    compound = cq.Compound.makeCompound(parts)
    exporters.export(compound, filepath, exportType=exporters.ExportTypes.STL)

    size_kb = os.path.getsize(filepath) / 1024
    print(f"[OK] STL exported: {filepath}")
    print(f"     File size: {size_kb:.1f} KB")
    print("Done! Refresh the viewer.")
