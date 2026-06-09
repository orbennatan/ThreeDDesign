from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle


OUT = "exports/profile_schedule_he.pdf"
FONT = r"C:\Windows\Fonts\arial.ttf"
FONT_BOLD = r"C:\Windows\Fonts\arialbd.ttf"


def rtl(text):
    """Simple Hebrew visual-order helper for ReportLab without python-bidi."""
    return text[::-1]


def mixed(hebrew, latin=""):
    if latin:
        return f"{latin}  {rtl(hebrew)}"
    return rtl(hebrew)


pdfmetrics.registerFont(TTFont("ArialHeb", FONT))
pdfmetrics.registerFont(TTFont("ArialHeb-Bold", FONT_BOLD))

doc = SimpleDocTemplate(
    OUT,
    pagesize=A4,
    rightMargin=16 * mm,
    leftMargin=16 * mm,
    topMargin=16 * mm,
    bottomMargin=16 * mm,
)

title = ParagraphStyle(
    "title",
    fontName="ArialHeb-Bold",
    fontSize=18,
    leading=24,
    alignment=2,
    textColor=colors.HexColor("#1f2933"),
    spaceAfter=8,
)

subtitle = ParagraphStyle(
    "subtitle",
    fontName="ArialHeb",
    fontSize=10,
    leading=14,
    alignment=2,
    textColor=colors.HexColor("#52606d"),
    spaceAfter=14,
)

cell = ParagraphStyle(
    "cell",
    fontName="ArialHeb",
    fontSize=9,
    leading=12,
    alignment=2,
)

head = ParagraphStyle(
    "head",
    fontName="ArialHeb-Bold",
    fontSize=9,
    leading=12,
    alignment=2,
    textColor=colors.white,
)


def p(text, style=cell):
    return Paragraph(text, style)


deck_rows = [
    ("קורות אורך ראשיות", "RHS 60x40x3 mm", "deck_only.scad"),
    ("קורות רוחב / לטות מתכת", "RHS 40x40x2 mm", "deck_only.scad"),
    ("עמודי תמיכה מתכווננים על סלע", "RHS 40x40x3 mm", "deck_only.scad"),
    ("פלטות בסיס לתמיכות", "180x180x10 mm", "deck_only.scad"),
    ("ברגי כיוון/פילוס בפלטות", "M16, h=120 mm", "deck_only.scad"),
    ("עמודי מעקה מבניים", "RHS 40x40x3 mm", "deck_only.scad"),
    ("מילוי אנכי במעקה", "Solid bar 10x10 mm", "deck_only.scad"),
    ("מרווח נקי בין מוטות המעקה", "90 mm", "deck_only.scad"),
    ("צינור עליון של המעקה", "Round tube D30x2 mm", "deck_only.scad"),
    ("לוחות איפאה", "140x20 mm, gap 1 mm", "deck_only.scad"),
]

stairs_rows = [
    ("מסגרות פודסט עליון ותחתון", "RHS 60x40x3 mm", "truss_stairs.scad"),
    ("עמודי תמיכה לפודסטים", "RHS 40x40x3 mm", "truss_stairs.scad"),
    ("קורות שדרה / סטרינגרים תחתונים", "RHS 80x40x3 mm", "truss_stairs.scad"),
    ("תמיכות אנכיות לקדמת המדרגות", "RHS 40x40x3 mm", "truss_stairs.scad"),
    ("עמודי מעקה מבניים במדרגות", "RHS 40x40x3 mm", "truss_stairs.scad"),
    ("קורה עליונה משופעת / מיתר עליון", "RHS 80x40x3 mm", "truss_stairs.scad"),
    ("מוטות מילוי/רשת טרס במדרגות", "RHS 20x20x2 mm", "truss_stairs.scad"),
    ("מילוי מעקה בפודסטים", "Solid bar 10x10 mm", "truss_stairs.scad"),
    ("קורה עליונה במעקה הפודסט", "30x30 mm", "truss_stairs.scad"),
    ("לוחות איפאה בפודסטים ובמדרגות", "140x20 mm / tread 280x1000x20", "truss_stairs.scad"),
]


def build_table(rows):
    data = [[p(rtl("קובץ"), head), p(rtl("מידה / פרופיל"), head), p(rtl("תפקיד"), head)]]
    for role, size, source in rows:
        data.append([p(source), p(size), p(rtl(role))])

    table = Table(data, colWidths=[40 * mm, 52 * mm, 82 * mm], repeatRows=1, hAlign="RIGHT")
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#334e68")),
                ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#bcccdc")),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 7),
                ("LEFTPADDING", (0, 0), (-1, -1), 7),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f8fafc")]),
            ]
        )
    )
    return table


story = [
    Paragraph(rtl("רשימת פרופילים לפרויקט דק ומדרגות"), title),
    Paragraph(rtl("סיכום מידות הפרופילים לפי תפקיד, מתוך הקבצים deck_only.scad ו-truss_stairs.scad."), subtitle),
    Paragraph(rtl("דק בלבד"), title),
    build_table(deck_rows),
    Spacer(1, 10 * mm),
    Paragraph(rtl("מערכת מדרגות"), title),
    build_table(stairs_rows),
    Spacer(1, 8 * mm),
    Paragraph(
        rtl("הערה: המסמך הוא רשימת מידות לייצור/בדיקה ואינו תחליף לאישור קונסטרוקטור, ריתוכים, עיגונים ופלטות בסיס."),
        subtitle,
    ),
]

doc.build(story)
print(OUT)
