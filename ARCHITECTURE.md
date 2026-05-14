# Architecture & Design Decisions

This document explains what the system does, how it works end-to-end, and **why** each
key decision was made — including the alternatives we considered and rejected.

---

## System Overview

```
┌──────────────────────────────────────────────────────────────────┐
│  Student devices                                                 │
│                                                                  │
│  ┌──────────────────┐         ┌──────────────────────────────┐  │
│  │  React Web App   │         │     Flutter Android App      │  │
│  │  (Vite + React)  │         │     (TFLite on-device)       │  │
│  │  localhost:3000  │         │                              │  │
│  └────────┬─────────┘         └──────────────┬───────────────┘  │
│           │ HTTP POST /recognize              │ TFLite inference │
└───────────┼──────────────────────────────────┼──────────────────┘
            │                                  │ (no network needed)
            ▼                                  │
  ┌──────────────────┐                         │
  │  FastAPI Server  │                         │
  │  localhost:8000  │                         │
  │  (Python/ONNX)   │                         │
  └────────┬─────────┘                         │
           │ ONNX Runtime                      │
           ▼                                   │
  ┌─────────────────────────────────────────┐  │
  │        Two-Stage ML Pipeline            │◄─┘
  │                                         │
  │  ① MobileNetV3 (224×224, fast)         │
  │     ↓ if confidence < 80%               │
  │  ② YOLOv11-small (640×640, accurate)   │
  └─────────────────────────────────────────┘
            │ All results
            ▼
  ┌──────────────────┐
  │  Supabase (PG)   │
  │  - menu_items    │
  │  - orders        │
  │  - scan_reports  │
  │  - food_nutrition│
  └──────────────────┘
```

---

## Decision 1 — ML Runtime: Python/ONNX on Server vs WASM in Browser

**Chosen:** Python FastAPI server running ONNX models via `onnxruntime`.

**Why not WASM in the browser?**

We initially tried `onnxruntime-web` (WebAssembly) so the web app could run inference
locally without a server. It failed immediately with:

```
no available backend found. ERR: [wasm] TypeError: SharedArrayBuffer is not defined
```

The root cause is a browser security restriction: `SharedArrayBuffer` (required for
multi-threaded WASM) is blocked unless the page is served with two HTTP headers:

```
Cross-Origin-Embedder-Policy: require-corp
Cross-Origin-Opener-Policy: same-origin
```

Vite's dev server does not set these by default, and adding them breaks third-party
scripts (Supabase JS SDK). Configuring Vite to emit them for WASM while keeping
Supabase working requires nontrivial header routing. In production it requires the
CDN/reverse-proxy to be configured too — adding infrastructure complexity for every
deployment.

The Python server approach is simpler: one `pip install`, one `python inference_server.py`
command, and it works everywhere with zero browser-security caveats.

**Why not Roboflow API?**

The original design used Roboflow to host the model and run inference via their API.
It was removed because:
1. The model was **not trained in Roboflow** — we trained it locally (MobileNet) and with
   Ultralytics (YOLO).
2. Roboflow API keys are per-workspace; the API returned 403 errors due to project/key
   mismatches.
3. Adding a third-party paid API to the inference path creates a runtime cost and a
   dependency we do not control.

---

## Decision 2 — Two-Stage Pipeline: MobileNetV3 → YOLOv11-small

**Why two models instead of one?**

| Model | Size | Speed | Accuracy |
|---|---|---|---|
| MobileNetV3 | ~14 MB | ~50 ms | Good on unambiguous images |
| YOLOv11-small | ~37 MB | ~200 ms | Better on partial/occluded food |

Using only MobileNet: fast but drops to ~60% accuracy on overlapping or partially
visible food items.

Using only YOLO: accurate but ~4× slower and larger — too heavy for the Flutter on-device
first-pass.

The two-stage design gets the best of both: MobileNet answers ~80% of scans instantly;
YOLO is invoked only when MobileNet is uncertain (confidence < 80%). Average latency
stays close to MobileNet's, while worst-case accuracy matches YOLO's.

---

## Decision 3 — Flutter: TFLite On-Device vs HTTP Server

**Chosen:** TFLite on-device for the Flutter app; HTTP server only for the web app.

**Why on-device for Flutter?**

- The inference server runs on the developer's laptop — it is not deployed to the cloud
  yet. The Flutter app must work in the field without requiring a network connection to
  a specific server.
- `tflite_flutter` 0.12 provides fast on-device inference with hardware acceleration
  (Android NNAPI / GPU delegate).
- On-device keeps user food photos private — images never leave the phone.

**TFLite format vs ONNX**

ONNX is the canonical export format from PyTorch/Ultralytics. We convert:

```
PyTorch → ONNX → TFLite (via onnx2tf + TensorFlow)
```

This is a one-time step per model version. The conversion script is at
`convert_mobilenet_to_tflite.py`. TFLite is the only ML format natively supported
by `tflite_flutter` without additional C++ libraries.

**Note on model assets in git**

TFLite/ONNX models are 14–54 MB each and change rarely. Putting them in git would bloat
the repo history permanently. They are:
- **Gitignored** in both repos
- Stored locally in `model/` (ONNX) and `food_app1_flutter/assets/models/` (TFLite)
- For CI/CD: stored as base64-encoded repository secrets, decoded at build time

---

## Decision 4 — Database: Supabase vs Custom Backend

**Chosen:** Supabase (hosted Postgres + Auth + Row Level Security).

**Why Supabase?**

The app needs: user authentication, a relational database, file storage (images), and
real-time capabilities (order status). Building and hosting all of this from scratch
would require a Node/Python server, a Postgres instance, and a session-management layer.

Supabase provides all of this with:
- **Free tier** sufficient for a campus-scale deployment
- **Row Level Security (RLS)** so the database enforces access rules — students can only
  read their own orders, admins can read everything
- **Anon key** is safe to ship in client-side code because RLS blocks unauthorised reads
- **supabase_flutter** SDK and `@jsr/supabase__supabase-js` for zero-config auth in both
  apps

**Alternatives considered:**
- Firebase: similar managed offering, but SQL (Postgres) is preferable for relational
  menu/order data over Firestore's document model.
- Custom Express + Postgres: more control, but adds hosting cost and maintenance.

---

## Decision 5 — Web App Styling: Inline Styles Instead of Tailwind in FoodScan

The project uses Tailwind CSS v4 (JIT / pre-compiled). In v4, classes not present in
the build-time scan of source files are not emitted. The `FoodScan.tsx` component was
added after the initial build and used many Tailwind classes not seen elsewhere in the
app.

Rather than modifying the Tailwind config or triggering a full rebuild for every new
class, all styles in `FoodScan.tsx` use React's inline `style={}` prop. This is
intentional and documented — it is not laziness but a workaround for the Tailwind v4
JIT limitation.

---

## Decision 6 — Hosting Choices

| Component | Recommendation | Why |
|---|---|---|
| Web app (React/Vite) | **Vercel** | Zero-config for Vite; free tier; edge CDN; preview deploys on PRs |
| Inference server (FastAPI) | **Railway** | Persistent containers; easy Docker deploy; free starter tier; no sleep on inactivity |
| Flutter APK | **GitHub Releases** | Tag-triggered CI builds the APK and attaches it to a Release automatically |
| Database | **Supabase** (already hosted) | Already running; no migration needed |

**Why Vercel over GitHub Pages?**

GitHub Pages serves static files from a branch, which works, but:
- It does not support environment variables at build time (no `VITE_` vars injected)
- Preview deploys per PR require additional tooling
- Vercel has native Vite support and injects env vars from the dashboard

**Why Railway over Render for the inference server?**

- Render's free tier "sleeps" services after 15 minutes of inactivity; the first request
  after sleep takes 30–50 seconds to respond — unacceptable for a scan feature.
- Railway keeps containers running and charges only for CPU/RAM usage, so an idle server
  costs nearly nothing.

---

## ML Pipeline: Model Update Workflow

When models are retrained (more data collected from `scan_reports`):

```
1. Retrain
   cd model/
   python train_mobilenet.py   # → mobilenet_food.onnx
   yolo train ...              # → best.onnx (YOLOv11-small)

2. Export for web server
   Copy new .onnx files to model/ folders.
   Restart inference_server.py (hot-reload not supported — just restart).

3. Export for Flutter
   python convert_mobilenet_to_tflite.py
   # Outputs mobilenet_food.tflite → food_app1_flutter/assets/models/

   # For YOLO TFLite, use Ultralytics export:
   yolo export model=best.pt format=tflite imgsz=640
   cp best_float16.tflite food_app1_flutter/assets/models/yolo_small.tflite

4. Commit model assets (not the .onnx files — only .tflite via CI secrets)
   flutter pub get
   flutter build apk --release

5. Update labels if classes changed
   Edit food_app1_flutter/assets/models/food_labels.txt
   Edit food_app/src/components/FoodScan.tsx  (ALL_CLASSES constant)
   Edit food_app1_flutter/lib/screens/scan/food_scan_screen.dart  (_allClasses constant)
```

---

## Data Flow: Scan Feature

### Web App

```
User presses shutter
  → canvas.getContext('2d').drawImage(video)
  → canvas.toBlob() → FormData
  → POST http://localhost:8000/recognize
      FastAPI receives image bytes
      → Pillow decodes, resizes to 224×224
      → MobileNetV3 ONNX inference (NCHW [1,3,224,224], ImageNet norm)
      → softmax → top-1 confidence
      → if conf < 0.80: resize to 640×640, YOLOv11-small ONNX inference
      → return {model_used, top_confidence, predictions[]}
  ← React receives JSON
  → Show results + model badge
  → Fetch food_nutrition_reference from Supabase
  → Fetch matching menu_items from Supabase
  → User optionally submits scan_reports row
```

### Flutter App

```
User presses shutter
  → CameraController.takePicture() → File
  → FoodRecognitionService.recognize(file)
      → image package: decodeImage, copyResize 224×224
      → [1,224,224,3] NHWC, ImageNet norm
      → tflite_flutter: Interpreter.run()
      → custom softmax in Dart
      → if conf < 0.80: resize 640×640, run YOLOv11-small TFLite
      → [1,8400,36] output: max class score per anchor
      → return RecognitionOutput {results, modelUsed, topConfidence}
  → showModalBottomSheet (_ResultsSheet)
      → Query food_nutrition_reference via Supabase
      → Show nutrition card + model badge + matched menu items
      → User optionally submits scan_reports row
```

---

## Input Normalisation — Critical Detail

MobileNetV3 was trained with **ImageNet normalisation**:

```
pixel_norm = (pixel_rgb / 255.0 - mean) / std
mean = [0.485, 0.456, 0.406]
std  = [0.229, 0.224, 0.225]
```

YOLOv11-small uses **simple 0–1 normalisation**:

```
pixel_norm = pixel_rgb / 255.0
```

Getting this wrong causes near-zero confidence on every class. Both the Python server
and the Flutter service use the correct normalisation for each model.

---

## Security Notes

| Secret | Where | Risk |
|---|---|---|
| Supabase anon key | Hardcoded in client code | **Safe** — RLS enforces access rules |
| Supabase service_role key | Nowhere in code | Must never be added |
| VITE_ROBOFLOW_API_KEY | `.env` (gitignored) | Not used anymore |
| SUPABASE_ACCESS_TOKEN | GitHub Actions secret | Used only for edge function deploy |
| VERCEL_TOKEN | GitHub Actions secret | Optional; only needed if using GH Actions deploy |
| YOLO_MODEL_B64 | GitHub Actions secret | Base64-encoded TFLite model for CI APK build |
