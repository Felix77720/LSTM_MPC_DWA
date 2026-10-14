from pathlib import Path
import matplotlib as mpl
mpl.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse, Polygon
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[6] / '.agents' / 'skills' / 'nature-figure' / 'scripts'))
from audit_panel_alignment import require_matplotlib_panel_alignment
import numpy as np

OUT = Path(__file__).resolve().parents[1] / '02_source' / 'figures'
OUT.mkdir(parents=True, exist_ok=True)

mpl.rcParams.update({
    'font.family': 'sans-serif',
    'font.sans-serif': ['Arial', 'Helvetica', 'DejaVu Sans'],
    'font.size': 7.0,
    'svg.fonttype': 'none',
    'pdf.fonttype': 42,
    'axes.linewidth': 0.7,
})

# Conceptual 3D problem scene, separate from measured route outcomes.
fig, ax = plt.subplots(figsize=(3.38, 2.53), facecolor='white')
ax.set_facecolor('white')

# Isometric projection keeps the bounded workspace readable at one-column width.
def P(point):
    x, y, z = point
    return np.array([0.866 * x - 0.5 * y, 0.227 * x + 0.423 * y + 0.891 * z])

def poly3(points, **kwargs):
    ax.add_patch(Polygon([P(p) for p in points], closed=True, **kwargs))

def line3(a, b, **kwargs):
    aa, bb = P(a), P(b)
    ax.plot([aa[0], bb[0]], [aa[1], bb[1]], **kwargs)

O = (0, 0, 0); X = (20, 0, 0); XY = (20, 20, 0); Y = (0, 20, 0)
Oz = (0, 0, 10); Xz = (20, 0, 10); XYz = (20, 20, 10); Yz = (0, 20, 10)
poly3([O, X, Xz, Oz], facecolor='#eef4f7', edgecolor='none', alpha=0.78, zorder=0)
poly3([Y, XY, XYz, Yz], facecolor='#f4f7f8', edgecolor='none', alpha=0.80, zorder=0)
poly3([O, X, XY, Y], facecolor='#f7fafb', edgecolor='none', zorder=0)
for v in (5, 10, 15):
    line3((v, 0, 0), (v, 20, 0), color='#dbe4e8', lw=0.45, zorder=1)
    line3((0, v, 0), (20, v, 0), color='#dbe4e8', lw=0.45, zorder=1)
for a, b in [(O, X), (X, XY), (XY, Y), (Y, O), (Oz, Xz), (Xz, XYz), (XYz, Yz), (Yz, Oz), (O, Oz), (X, Xz), (XY, XYz), (Y, Yz)]:
    line3(a, b, color='#738994', lw=0.85, zorder=2)

start = (1, 1, 1)
goal = (18, 18, 8)
uav = np.asarray(start, dtype=float)
# The UAV glyph and start marker represent the same 3-D state. Project once
# and reuse this point so the marker cannot drift to a ground-plane projection.
s0, g0 = P(uav), P(goal)
# Dashed start-to-goal line is a geometric cue, not a simulated trajectory.
ax.plot([s0[0], g0[0]], [s0[1], g0[1]], color='#778d99', lw=0.9,
        ls=(0, (2.2, 2.4)), alpha=0.9, zorder=2)

# Illustrative moving spherical obstacles and their prescribed motion directions.
obstacles = [
    ((6.7, 8.2, 2.5), (9.2, 6.9, 3.2), 1.55),
    ((13.3, 10.7, 5.4), (11.2, 13.2, 5.8), 1.70),
    ((15.4, 16.6, 8.0), (17.3, 14.8, 8.4), 1.35),
]
for centre, end, radius in obstacles:
    c, e = P(centre), P(end)
    mid = P(((centre[0] + end[0]) / 2, (centre[1] + end[1]) / 2, (centre[2] + end[2]) / 2))
    ax.plot([c[0] - (e[0]-c[0])*1.25, e[0]], [c[1] - (e[1]-c[1])*1.25, e[1]],
            color='#d58c73', lw=0.8, ls=(0, (2.0, 2.0)), alpha=0.78, zorder=3)
    ax.annotate('', xy=e, xytext=mid,
                arrowprops=dict(arrowstyle='-|>', color='#c66d52', lw=1.0, mutation_scale=7), zorder=5)
    w, h = 2 * radius * 0.72, 2 * radius * 0.53
    ax.add_patch(Ellipse(c + np.array([0.05, -0.07]), w * 1.07, h * 1.07,
                         facecolor='#8799a3', edgecolor='none', alpha=0.16, zorder=4))
    ax.add_patch(Ellipse(c, w, h, facecolor='#cf745b', edgecolor='#9c4e3c',
                         linewidth=0.8, alpha=0.87, zorder=6))
    ax.add_patch(Ellipse(c + np.array([-w*0.16, h*0.13]), w*0.28, h*0.30,
                         facecolor='#f4c3ad', edgecolor='none', alpha=0.8, zorder=7))
    ax.add_patch(Ellipse(c, 0.10, 0.10, facecolor='#713d35', edgecolor='none', zorder=8))

# Quadrotor with visible arms, guarded rotors, central body, battery and camera/gimbal.
rotors = [(-0.82, -0.68, 0.12), (-0.82, 0.68, 0.12),
          (0.82, -0.68, 0.12), (0.82, 0.68, 0.12)]
for dx, dy, dz in rotors:
    line3(uav, (uav[0]+dx, uav[1]+dy, uav[2]+dz), color='#283a46', lw=1.65, zorder=10)
for dx, dy, dz in rotors:
    c = P((uav[0]+dx, uav[1]+dy, uav[2]+dz))
    ax.add_patch(Ellipse(c, 0.94, 0.39, facecolor='#e4edf1', edgecolor='#283a46',
                         linewidth=0.8, alpha=0.96, zorder=11))
    ax.add_patch(Ellipse(c, 0.19, 0.12, facecolor='#566d79', edgecolor='white',
                         linewidth=0.45, zorder=12))
c = s0
ax.add_patch(Ellipse(c, 0.82, 0.49, facecolor='#263b48', edgecolor='#142833',
                     linewidth=0.85, zorder=13))
ax.add_patch(Ellipse(c + np.array([0, 0.045]), 0.34, 0.15, facecolor='#597280',
                     edgecolor='none', zorder=14))
ax.plot([c[0], c[0]], [c[1]+0.15, c[1]+0.28], color='#263b48', lw=1.25, zorder=14)
ax.add_patch(Ellipse(c + np.array([0, 0.31]), 0.14, 0.14, facecolor='#e5a343',
                     edgecolor='#805421', linewidth=0.65, zorder=15))
ax.add_patch(Ellipse(c + np.array([0, 0.31]), 0.055, 0.055, facecolor='#263b48',
                     edgecolor='white', linewidth=0.45, zorder=16))
ax.annotate('UAV', xy=c, xytext=(c[0]+2.9, c[1]+3.1), fontsize=6.4,
            color='#263b48', ha='center', va='center', zorder=22,
            arrowprops=dict(arrowstyle='-', color='#526a76', lw=0.65,
                            shrinkA=4, shrinkB=5))

ax.scatter([c[0]], [c[1]], marker='o', s=48, facecolors='none',
           edgecolors=['#158477'], linewidths=1.1, zorder=20)
ax.scatter([g0[0]], [g0[1]], marker='*', s=86, c=['#e2a132'], edgecolors='#91641d',
           linewidths=0.65, zorder=20)

ax.text(g0[0]+3.0, g0[1]-1.8, 'goal', fontsize=6.8, color='#805b1f', ha='left', va='center', zorder=21)
ax.text(-6.0, 20.55, 'bounded 3-D workspace', fontsize=6.7, color='#425b68',
        ha='center', va='center', zorder=22)

key_y = -0.42
ax.plot([-10.5, -8.5], [key_y, key_y], color='#778d99', lw=0.85, ls=(0, (2.2, 2.4)), clip_on=False)
ax.text(-8.1, key_y, 'goal direction', fontsize=6.2, color='#536a75', va='center')
ax.add_patch(Ellipse((1.6, key_y), 0.55, 0.40, facecolor='#cf745b', edgecolor='#9c4e3c', lw=0.65))
ax.text(2.05, key_y, 'moving obstacle', fontsize=6.2, color='#536a75', va='center')
ax.add_patch(Ellipse((9.2, key_y), 0.42, 0.42, facecolor='none',
                     edgecolor='#158477', linewidth=0.9))
ax.text(9.6, key_y, 'start', fontsize=6.2, color='#536a75', va='center')

ax.set_xlim(-12.0, 20.0)
ax.set_ylim(-1.0, 23.0)
ax.set_aspect('equal', adjustable='box')
ax.axis('off')
fig.subplots_adjust(left=0.01, right=0.99, bottom=0.015, top=0.985)
require_matplotlib_panel_alignment(fig, json_out=OUT / 'scenario_schematic_alignment.json', overlay_svg=OUT / 'scenario_schematic_alignment.svg', tolerance_pt=1.5, gutter_tolerance_pt=1.5, strict=True)
fig.savefig(OUT / 'scenario_schematic.pdf', facecolor='white')
fig.savefig(OUT / 'scenario_schematic.svg', facecolor='white')
fig.savefig(OUT / 'scenario_schematic.png', dpi=600, facecolor='white')
fig.savefig(OUT / 'scenario_schematic.tiff', dpi=600, facecolor='white')
plt.close(fig)
print(f'Wrote revised conceptual scene figure to {OUT}')




