# Chat History
This file will contain a running summary of all actions, changes, and key decisions made during this session in the ThreeDDesign workspace. Each entry will be timestamped and include a concise description of what was done.

## 2026-05-20  
## 2026-05-20  - Bar and edge size analysis
- User requested examination of long bar sizes (width, profile) and edge support for 1, 2, and 3 vertical support bars.
- Located all bar/profile size definitions in models/deck.scad and generate_model.py (main_w, main_h, joist_w, joist_h, pole_w, pole_h, ipe_w, ipe_thick, etc.).
- Found that bar width/profile is set by these variables, not by the number of vertical supports; support bars are placed at fixed positions.
- Edge calculations and display logic are handled in static/js/viewer.js (addEdges, updateModelInfo, etc.).
- No code found for dynamically changing bar width/profile based on number of vertical supports; all bars use fixed profiles.
- Outcome: Bar and edge sizes are fixed by profile variables, not by support count.
- Set up the rule to append a summary entry after every action taken in this workspace.

---
