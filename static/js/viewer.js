/**
 * 3D CAD Viewer - Three.js Engine (ES Module)
 * Handles scene setup, STL loading, camera controls, and display options.
 */

import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { STLLoader } from 'three/addons/loaders/STLLoader.js';

// ===================== Scene Setup =====================
const canvas = document.getElementById('cad-canvas');
const viewportEl = document.getElementById('viewport');

const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: false });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setClearColor(0x0a0e17);
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.2;

const scene = new THREE.Scene();

// Camera
const camera = new THREE.PerspectiveCamera(45, 1, 0.1, 100000);
camera.position.set(120, 80, 120);

// Controls
const controls = new OrbitControls(camera, canvas);
controls.enableDamping = true;
controls.dampingFactor = 0.08;
controls.rotateSpeed = 0.8;
controls.zoomSpeed = 1.2;
controls.panSpeed = 0.6;
controls.minDistance = 5;
controls.maxDistance = 50000;

// ===================== Lighting =====================
scene.add(new THREE.AmbientLight(0x404860, 0.6));

const keyLight = new THREE.DirectionalLight(0xffffff, 1.2);
keyLight.position.set(100, 150, 100);
keyLight.castShadow = true;
keyLight.shadow.mapSize.set(2048, 2048);
scene.add(keyLight);

const fillLight = new THREE.DirectionalLight(0x8896b3, 0.4);
fillLight.position.set(-80, 60, -80);
scene.add(fillLight);

const rimLight = new THREE.DirectionalLight(0x6382ff, 0.3);
rimLight.position.set(0, -50, -100);
scene.add(rimLight);

// ===================== Grid =====================
const gridHelper = new THREE.GridHelper(10000, 100, 0x1a2235, 0x141c2e);
scene.add(gridHelper);

const groundGeo = new THREE.PlaneGeometry(20000, 20000);
const groundMat = new THREE.MeshStandardMaterial({
  color: 0x0d1220, roughness: 0.95, metalness: 0, transparent: true, opacity: 0.6
});
const ground = new THREE.Mesh(groundGeo, groundMat);
ground.rotation.x = -Math.PI / 2;
ground.position.y = -0.1;
ground.receiveShadow = true;
scene.add(ground);

// ===================== State =====================
let currentMesh = null;
let edgeLines = null;
let modelColor = '#6382ff';
let showWireframe = false;
let showEdges = true;
let showGrid = true;
let isPerspective = true;
let modelLoaded = false;

// ===================== Resize =====================
function onResize() {
  const w = viewportEl.clientWidth;
  const h = viewportEl.clientHeight;
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
  renderer.setSize(w, h);
}
window.addEventListener('resize', onResize);
onResize();

// ===================== Animation =====================
function animate() {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
}
animate();

// ===================== Model Loading =====================
const stlLoader = new STLLoader();

function loadModel(filename) {
  const overlay = document.getElementById('loading-overlay');
  overlay.classList.add('visible');
  document.getElementById('welcome-screen').style.display = 'none';

  // Remove previous model
  if (currentMesh) { scene.remove(currentMesh); currentMesh = null; }
  if (edgeLines) { scene.remove(edgeLines); edgeLines = null; }

  stlLoader.load('/api/models/' + filename, function (geometry) {
    geometry.computeVertexNormals();
    geometry.center();

    const material = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(modelColor),
      metalness: 0.15,
      roughness: 0.35,
      clearcoat: 0.3,
      clearcoatRoughness: 0.25,
      side: THREE.DoubleSide,
      wireframe: showWireframe,
    });

    currentMesh = new THREE.Mesh(geometry, material);
    currentMesh.castShadow = true;
    currentMesh.receiveShadow = true;
    scene.add(currentMesh);

    if (showEdges) { addEdges(geometry); }
    updateModelInfo(geometry);
    fitToView();

    overlay.classList.remove('visible');
    document.getElementById('info-bar').style.display = 'flex';
    document.getElementById('viewport-hud').style.display = 'flex';
    modelLoaded = true;

    // Mark active in sidebar
    document.querySelectorAll('.model-item').forEach(el => el.classList.remove('active'));
    const activeItem = document.querySelector(`[data-model="${filename}"]`);
    if (activeItem) activeItem.classList.add('active');

  }, undefined, function (err) {
    console.error('Error loading model:', err);
    overlay.classList.remove('visible');
  });
}

function addEdges(geometry) {
  if (edgeLines) { scene.remove(edgeLines); }
  const edges = new THREE.EdgesGeometry(geometry, 30);
  const lineMat = new THREE.LineBasicMaterial({ color: 0x2a3550, linewidth: 1 });
  edgeLines = new THREE.LineSegments(edges, lineMat);
  scene.add(edgeLines);
}

function updateModelInfo(geometry) {
  const tris = geometry.index ? geometry.index.count / 3 : geometry.attributes.position.count / 3;
  const verts = geometry.attributes.position.count;
  document.getElementById('info-tris').textContent = Math.round(tris).toLocaleString();
  document.getElementById('info-verts').textContent = verts.toLocaleString();

  geometry.computeBoundingBox();
  const box = geometry.boundingBox;
  const sx = (box.max.x - box.min.x).toFixed(1);
  const sy = (box.max.y - box.min.y).toFixed(1);
  const sz = (box.max.z - box.min.z).toFixed(1);
  document.getElementById('info-size').textContent = `${sx} x ${sy} x ${sz}`;
}

// ===================== Camera Controls =====================
function fitToView() {
  if (!currentMesh) return;
  const box = new THREE.Box3().setFromObject(currentMesh);
  const size = box.getSize(new THREE.Vector3());
  const center = box.getCenter(new THREE.Vector3());
  const maxDim = Math.max(size.x, size.y, size.z);
  const fov = camera.fov * (Math.PI / 180);
  const dist = (maxDim / 2) / Math.tan(fov / 2) * 1.3;
  controls.target.copy(center);
  camera.position.set(center.x + dist * 0.6, center.y + dist * 0.4, center.z + dist * 0.6);
  camera.lookAt(center);
  controls.update();
}

function setCameraView(view) {
  if (!currentMesh) return;
  const box = new THREE.Box3().setFromObject(currentMesh);
  const center = box.getCenter(new THREE.Vector3());
  const size = box.getSize(new THREE.Vector3());
  const dist = Math.max(size.x, size.y, size.z) * 2;
  controls.target.copy(center);
  switch (view) {
    case 'front': camera.position.set(center.x, center.y, center.z + dist); break;
    case 'top':   camera.position.set(center.x, center.y + dist, center.z + 0.01); break;
    case 'right': camera.position.set(center.x + dist, center.y, center.z); break;
    case 'iso':   camera.position.set(center.x + dist*0.7, center.y + dist*0.5, center.z + dist*0.7); break;
  }
  camera.lookAt(center);
  controls.update();
}

// ===================== Display Toggles =====================
function toggleWireframe() {
  showWireframe = !showWireframe;
  document.getElementById('toggle-wireframe').classList.toggle('active', showWireframe);
  if (currentMesh) currentMesh.material.wireframe = showWireframe;
}

function toggleEdges() {
  showEdges = !showEdges;
  document.getElementById('toggle-edges').classList.toggle('active', showEdges);
  if (showEdges && currentMesh) {
    addEdges(currentMesh.geometry);
  } else if (edgeLines) {
    scene.remove(edgeLines);
    edgeLines = null;
  }
}

function toggleGrid() {
  showGrid = !showGrid;
  document.getElementById('toggle-grid').classList.toggle('active', showGrid);
  gridHelper.visible = showGrid;
  ground.visible = showGrid;
}

function toggleAutoRotate() {
  controls.autoRotate = !controls.autoRotate;
  controls.autoRotateSpeed = 2;
  document.getElementById('toggle-rotate').classList.toggle('active', controls.autoRotate);
}

// ===================== Model List =====================
function refreshModels() {
  fetch('/api/models')
    .then(r => r.json())
    .then(data => {
      const list = document.getElementById('model-list');
      if (!data.models || data.models.length === 0) {
        list.innerHTML = '<div class="empty-state"><div class="icon">&#128230;</div><div>No models yet.</div></div>';
        return;
      }
      list.innerHTML = data.models.map(m => {
        const sizeKB = (m.size / 1024).toFixed(1);
        return `<div class="model-item" data-model="${m.name}">
          <div class="icon">&#128297;</div>
          <div class="info">
            <div class="name">${m.name}</div>
            <div class="meta">${sizeKB} KB</div>
          </div>
        </div>`;
      }).join('');

      // Bind click events
      list.querySelectorAll('.model-item').forEach(item => {
        item.addEventListener('click', () => loadModel(item.dataset.model));
      });

      // Auto-load first model if none loaded yet
      if (data.models.length > 0 && !modelLoaded) {
        loadModel(data.models[0].name);
      }
    })
    .catch(err => console.error('Failed to fetch models:', err));
}

// ===================== Event Bindings =====================
document.getElementById('btn-refresh').addEventListener('click', refreshModels);
document.getElementById('btn-reset-camera').addEventListener('click', () => {
  camera.position.set(120, 80, 120);
  controls.target.set(0, 0, 0);
  controls.update();
});
document.getElementById('btn-fit').addEventListener('click', fitToView);
document.getElementById('btn-projection').addEventListener('click', () => {
  isPerspective = !isPerspective;
  camera.fov = isPerspective ? 45 : 5;
  camera.updateProjectionMatrix();
});

document.getElementById('toggle-wireframe').addEventListener('click', toggleWireframe);
document.getElementById('toggle-edges').addEventListener('click', toggleEdges);
document.getElementById('toggle-grid').addEventListener('click', toggleGrid);
document.getElementById('toggle-rotate').addEventListener('click', toggleAutoRotate);

document.querySelectorAll('[data-view]').forEach(btn => {
  btn.addEventListener('click', () => setCameraView(btn.dataset.view));
});

document.getElementById('color-swatches').addEventListener('click', e => {
  const swatch = e.target.closest('[data-color]');
  if (swatch) {
    modelColor = swatch.dataset.color;
    if (currentMesh) currentMesh.material.color.set(modelColor);
  }
});

// ===================== Init =====================
refreshModels();
