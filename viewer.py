"""
3D CAD Viewer - Flask web server.

Serves the Three.js-based viewer and provides API endpoints
for loading STL models exported by generate_model.py.
"""

import os
import glob
from flask import Flask, send_from_directory, jsonify, send_file

app = Flask(__name__, static_folder="static", template_folder="templates")

EXPORT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "exports")


@app.route("/")
def index():
    """Serve the main viewer page."""
    return send_file(os.path.join("templates", "viewer.html"))


@app.route("/api/models")
def list_models():
    """List all available STL models in the exports directory."""
    if not os.path.exists(EXPORT_DIR):
        return jsonify({"models": []})
    
    stl_files = glob.glob(os.path.join(EXPORT_DIR, "*.stl"))
    models = [
        {
            "name": os.path.basename(f),
            "size": os.path.getsize(f),
            "modified": os.path.getmtime(f),
        }
        for f in sorted(stl_files, key=os.path.getmtime, reverse=True)
    ]
    return jsonify({"models": models})


@app.route("/api/models/<filename>")
def get_model(filename):
    """Serve a specific STL file."""
    if not filename.endswith(".stl"):
        return jsonify({"error": "Only STL files supported"}), 400
    return send_from_directory(EXPORT_DIR, filename)


@app.route("/static/<path:path>")
def serve_static(path):
    """Serve static assets (JS, CSS)."""
    return send_from_directory("static", path)


if __name__ == "__main__":
    print("\n" + "=" * 60)
    print("  3D CAD Viewer")
    print("=" * 60)
    print(f"  Export dir: {EXPORT_DIR}")
    
    # Check if there are models to display
    if os.path.exists(EXPORT_DIR):
        stl_count = len(glob.glob(os.path.join(EXPORT_DIR, "*.stl")))
        print(f"  Models found: {stl_count}")
    else:
        print("  [!] No exports found. Run 'python generate_model.py' first!")
    
    print(f"\n  Open in browser: http://localhost:5050")
    print("=" * 60 + "\n")
    
    app.run(host="0.0.0.0", port=5050, debug=True)
