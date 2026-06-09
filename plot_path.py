pts = [(-580, 0), (-580, -300), (-673, -585), (-849, -828), (-1092, -1004),
       (-1377, -1097), (-1675, -1131), (-1974, -1105), (-2262, -1020),
       (-2527, -879), (-2758, -688), (-2947, -455), (-3085, -189),
       (-3168, 100), (-3192, 399)]

W, H = 72, 26
xmin, xmax = -3400, 300
ymin, ymax = -2000, 650


def col(x):
    return int((x - xmin) / (xmax - xmin) * (W - 1))


def row(y):
    return int((ymax - y) / (ymax - ymin) * (H - 1))


g = [[' '] * W for _ in range(H)]

# leg A : x[0,150] y[-1640,0]
for xx in range(0, 151, 15):
    for yy in range(-1640, 1, 30):
        g[row(yy)][col(xx)] = '#'
# leg B : x[-1100,0] y[-1790,-1640]
for xx in range(-1100, 1, 20):
    for yy in range(-1790, -1639, 15):
        g[row(yy)][col(xx)] = '#'
# south floor edge y=-1900
for xx in range(xmin, xmax, 40):
    g[row(-1900)][col(xx)] = '-'
# path points
for i, (x, y) in enumerate(pts):
    c = str(i) if i < 10 else chr(ord('a') + i - 10)
    g[row(y)][col(x)] = c
# wall tip
g[row(-1640)][col(-1100)] = 'T'

print('  LEFT = -x = "east"   DOWN = -y = south    #=wall  T=tip  -=south floor edge')
for r in g:
    print(''.join(r))
print('  0 = deck top of stairs ... e = last (lowest) tread, facing NORTH')
