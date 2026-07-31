# CORNELIA

**CORNELIA** is an AI-powered analytics platform for turning raw user comments and feedback into structured insight — sentiment, emotion, topics, trends, and demographic breakdowns — through a cross-platform Flutter app backed by a Python NLP inference server.

---

## Overview

CORNELIA is built for teams that collect large volumes of unstructured text feedback (app reviews, survey responses, social comments, etc.) and need to understand what people are actually saying — not just read through it one comment at a time.

The system has two parts:

1. **Flutter client** — a single codebase that runs on Android, iOS, macOS, Windows, Linux, and web. Users upload/tag comment data and explore it through interactive dashboards (charts, maps, word clouds, network graphs).
2. **Flask inference backend** — a stateless NLP server that wraps several Hugging Face models and classical ML techniques (clustering, embeddings, keyword extraction) behind a small REST API. The Flutter app calls this backend to turn raw comment batches into ready-to-visualize analytics.

---

## Architecture

```
┌─────────────────────────┐        HTTPS / JSON        ┌──────────────────────────────┐
│      CORNELIA App        │  ────────────────────────▶ │      CORNELIA Backend        │
│   (Flutter, multi-       │                             │   (Flask + Hugging Face      │
│    platform client)      │  ◀──────────────────────── │    Transformers, sklearn)    │
└─────────────────────────┘        analytics JSON        └──────────────────────────────┘
        │                                                          │
        │                                                          ├─ Sentiment analysis
        ├─ Firebase Auth (login/register)                          ├─ Emotion classification
        ├─ Cloud Firestore (comment/tag storage)                   ├─ Topic clustering (HDBSCAN/KMeans)
        ├─ Firebase Storage                                        ├─ Keyword extraction (KeyBERT)
        └─ Gemini (in-app AI assistance)                           └─ Demographic/aspect analysis
```

---

## Features

Based on the app's screens and analytics widgets, CORNELIA supports:

- **Authentication** — login/registration flows backed by Firebase Auth
- **Comment tagging & search** — upload, tag, and search through comment datasets
- **Sentiment analysis** — overall positive/neutral/negative breakdowns, sentiment over time, and sentiment by country/gender
- **Emotion analysis** — fine-grained emotion distribution (28 GoEmotions categories, condensed to the top signals)
- **Topic modeling** — automatic clustering of comments into themes, with an intertopic distance map for visualizing how topics relate
- **Keyword network graphs** — co-occurrence graphs showing which keywords/themes appear together
- **Emerging issues / trend detection** — tracks how topics and keywords trend over time
- **Age-group aspect sentiment** — breaks down sentiment by age bracket and by specific aspects mentioned within each bracket
- **Negative outlier detection** — surfaces the most negative individual comments for review
- **Toxicity & controversy scoring**
- **"Dead internet" detection** (likely bot/spam-pattern detection)
- **Word clouds, choropleth maps, and a range of chart types** (bar, grouped bar, horizontal bar, donut, radar, area, line) for visual exploration
- **Executive summary & key insights** — auto-generated high-level takeaways
- **Gemini-powered in-app AI assistance**

> Note: feature descriptions above are inferred from file/route names (`lib/pages/`, `lib/data_analysis_tools/`) and may not capture full behavior — see the source files for exact logic.

---

## Tech Stack

### Frontend (Flutter app)
- **Framework:** Flutter (Dart SDK ^3.11.1)
- **Backend-as-a-service:** Firebase (Auth, Cloud Firestore, Storage)
- **AI assistant:** `flutter_gemini`
- **Charts & visualization:** `fl_chart`, `syncfusion_flutter_charts`, `syncfusion_flutter_maps`, `graphview`, `word_cloud`
- **Other notables:** `google_sign_in`, `country_picker`, `file_picker`, `image_picker`, `google_fonts`, `lottie`, `fluttertoast`, `flutter_easyloading`

### Backend (NLP inference server)
- **Framework:** Flask + Flask-CORS
- **NLP/ML:** Hugging Face `transformers`, `sentence-transformers`, `KeyBERT`, `scikit-learn`, `nltk`, optional `hdbscan` / `umap-learn`
- **Models used:**

  | Model | Purpose |
  |---|---|
  | `cardiffnlp/twitter-roberta-base-sentiment-latest` | 3-class sentiment (positive/neutral/negative) |
  | `SamLowe/roberta-base-go_emotions` | 28-category emotion classification |
  | `sentence-transformers/all-MiniLM-L6-v2` | Text embeddings for clustering, keyword graphs, trend detection |
  | KeyBERT (built on MiniLM) | Keyword/keyphrase extraction with MMR diversity |

---

## Backend API Reference

Base URL: wherever the Flask server is deployed (e.g. a Hugging Face Space or your own host).

| Method & Path | Description |
|---|---|
| `GET /` | Human-readable status page describing loaded models |
| `GET /health` | Health check — returns `{"status": "ok"}` |
| `POST /roberta-base-sentiment` | Overall sentiment % breakdown for a list of comments |
| `POST /roberta-base-sentiment-SOT` | Sentiment labeled per comment with date, for sentiment-over-time charts |
| `POST /roberta-base-sentimentCO` | Sentiment breakdown grouped by country and gender |
| `POST /roberta-base-sentiment-SCORES` | Per-comment negative-sentiment score (for outlier detection) |
| `POST /roberta-base-go` | Top 5 non-neutral emotions with weighted scores |
| `POST /all-MiniLM-L6-v2` | Embeds + clusters comments into themes with keywords and 2D coordinates for a topic map |
| `POST /all-MiniLM-L6-v2-ETO` | Clusters comments and tracks keyword/theme mentions over time (emerging topics) |
| `POST /all-MiniLM-L6-v2-G` | Builds a keyword co-occurrence network graph (nodes + weighted edges) |
| `POST /all-MiniLM-L6-v2-COR` | Buckets comments by age group and computes sentiment + aspect-level sentiment per bucket |

All `POST` endpoints expect a JSON body and return `{"status": "success", "results": ...}` on success, or `{"status": "error", "message": ...}` with a `400` status if no data is provided. Refer to `app.py` for exact request/response shapes per endpoint, since several take structured objects (e.g. `{"text": ..., "date": ...}` or `{"text": ..., "country": ..., "gender": ..., "age": ...}`) rather than plain strings.

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (compatible with Dart ^3.11.1)
- A configured Firebase project (Auth, Firestore, Storage enabled)
- Python 3.10+ for the backend
- (Optional, backend) A Hugging Face account/token if pulling gated models or avoiding rate limits

### 1. Clone the repo

```bash
git clone https://github.com/chuajeromepython/CORNELIA.git
cd CORNELIA
```

### 2. Backend setup

```bash
cd <backend-directory>
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install flask flask-cors numpy nltk transformers huggingface_hub \
            sentence-transformers keybert scikit-learn
# Optional but recommended for better clustering:
pip install hdbscan umap-learn

# Set your Hugging Face token if needed (never hardcode it):
export HF_TOKEN=your_token_here      # Windows: set HF_TOKEN=your_token_here

python app.py
```

The server starts on `http://0.0.0.0:5000` by default. Confirm it's healthy at `GET /health`.

### 3. Flutter app setup

```bash
flutter pub get
```

Configure Firebase for your platforms (`flutterfire configure` or manually replace `lib/firebase_options.dart` / `android/app/google-services.json` / `ios/Runner/GoogleService-Info.plist` with your own project's config).

**⚠️ Security note:** `lib/main.dart` currently initializes the Gemini SDK with an API key hardcoded directly in source. Before running or publishing this app:
- Rotate/revoke that key in your Google AI Studio / Cloud console
- Pass it in at build time instead, e.g.:
  ```bash
  flutter run --dart-define=GEMINI_API_KEY=your_key_here
  ```
  and read it via `String.fromEnvironment('GEMINI_API_KEY')` in `main.dart`
- Add any secrets files to `.gitignore` so they're never committed again

Then point the app at your backend URL (wherever `app.py` is deployed) in whatever config/constants file it reads from in `lib/utilities` or `lib/helper_functions`.

### 4. Run the app

```bash
flutter run                # run on a connected device/emulator
flutter run -d chrome      # run in a browser
flutter run -d windows     # run as a Windows desktop app
```

---

## Project Structure

```
CORNELIA/
├── lib/
│   ├── main.dart                 # App entry point, Firebase/Gemini init
│   ├── firebase_options.dart     # Generated Firebase config
│   ├── pages/                    # App screens (auth, home, search, analytics, topics, tagging...)
│   ├── data_analysis_tools/      # Chart/graph/visualization widgets consuming backend analytics
│   ├── helper_functions/         # Shared utility logic
│   └── utilities/                # Shared constants/config
├── assets/                       # Logos, icons, splash images, map data
├── android/ ios/ macos/ windows/ linux/ web/   # Platform-specific Flutter scaffolding
├── firebase.json                 # Firebase project/platform config
├── pubspec.yaml                  # Flutter dependencies
└── <backend>/app.py              # Flask NLP inference server
```

---

## Environment Variables

| Variable | Used by | Purpose |
|---|---|---|
| `HF_TOKEN` | Backend | Authenticates with Hugging Face Hub (optional, avoids rate limits / enables gated models) |
| `GEMINI_API_KEY` *(recommended)* | Flutter app | Should replace the currently hardcoded Gemini key — pass via `--dart-define` |

---

## Notes & Caveats

- This README was reconstructed from the repository's file/folder structure, dependencies, and one backend source file, since the original `README.md` was a placeholder. Descriptions of individual screens and analytics tools are inferred from naming and may need refinement by someone familiar with the intended product behavior.
- The backend has no authentication on its endpoints as written — if deployed publicly, consider adding an API key or network restrictions so it isn't open to arbitrary use.
- CORS is currently wide open (`flask_cors.CORS(app)` with no restrictions) — scope this to your app's actual origin(s) before shipping.
