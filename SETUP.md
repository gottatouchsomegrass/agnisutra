-- Active: 1773140911707@@127.0.0.1@5432@agnisutra

# AgniSutra — Run Guide

## Prerequisites

| Tool                   | Version | Download                                     |
| ---------------------- | ------- | -------------------------------------------- |
| Python                 | ≥ 3.10  | [python.org](https://python.org)             |
| PostgreSQL             | ≥ 14    | [postgresql.org](https://www.postgresql.org) |
| Flutter                | ≥ 3.19  | [flutter.dev](https://flutter.dev)           |
| Android Studio / Xcode | Latest  | For device/emulator                          |

---

## 1 · Backend Setup

### 1.1 — Create & activate a virtual environment

```bash
cd agnisutra/backend
python -m venv venv

# Windows
venv\Scripts\activate

# macOS / Linux
source venv/bin/activate
```

### 1.2 — Install dependencies

```bash
pip install -r requirements.txt
```

### 1.3 — Configure environment variables

Create `backend/.env` (copy the template below):

```env
DATABASE_URL=postgresql://postgres:yourpassword@localhost:5432/agnisutra
SECRET_KEY=your_super_secret_key_here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
AGRO_API_KEY=your_agromonitoring_api_key
```

### 1.4 — Create the database

```bash
# In PostgreSQL shell
CREATE DATABASE agnisutra;
```

Tables are created automatically by SQLAlchemy on first startup.

### 1.5 — Start the backend

```bash
# From the backend/ directory, with venv active
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API is now live at `http://localhost:8000`  
Interactive docs: `http://localhost:8000/docs`

---

## 2 · Mobile App Setup

### 2.1 — Install Flutter dependencies

```bash
cd agnisutra/mobile
flutter pub get
```

### 2.2 — Set the backend URL

Edit `mobile/lib/constants.dart`:

```dart
class AppConstants {
  // Android Emulator → use 10.0.2.2
  // static const String baseUrl = 'http://10.0.2.2:8000';

  // Physical device → use your machine's local IP
  static const String baseUrl = 'http://192.168.x.x:8000';
}
```

> **How to find your local IP:**  
> Windows: `ipconfig` → look for **IPv4 Address** under your Wi-Fi adapter  
> macOS/Linux: `ifconfig` → look for `inet` under `en0`  
> Your phone and PC must be on the **same Wi-Fi network**.

### 2.3 — Enable Developer Mode (Windows only)

```
Start → Settings → For developers → Turn on Developer Mode
```

Required for Flutter symlinks on Windows.

### 2.4 — Connect a device or start an emulator

```bash
flutter devices          # list available devices
flutter emulators        # list installed emulators
flutter emulators --launch <emulator_id>
```

### 2.5 — Run the app

```bash
flutter run
```

For a specific device:

```bash
flutter run -d <device_id>
```

---

## 3 · Running Both Together (Quick Reference)

Open **two terminals**:

**Terminal 1 — Backend**

```bash
cd agnisutra/backend
venv\Scripts\activate        # Windows
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Terminal 2 — Mobile**

```bash
cd agnisutra/mobile
flutter run
```

---

## 4 · Troubleshooting

| Problem                          | Fix                                                                       |
| -------------------------------- | ------------------------------------------------------------------------- |
| `flutter pub get` fails          | Run `flutter upgrade` then retry                                          |
| App can't reach backend          | Check `constants.dart` IP matches your machine's LAN IP                   |
| `Connection refused` on emulator | Use `http://10.0.2.2:8000` not `localhost`                                |
| DB connection error              | Verify PostgreSQL is running and `.env` credentials are correct           |
| `MODULE_NOT_FOUND` for models    | Download model files (see `INTEGRATION_GUIDE.md`) and place in `backend/` |
| Flutter symlink error on Windows | Enable Developer Mode (see step 2.3)                                      |

---

## 5 · Project Structure (Quick Overview)

```
agnisutra/
├── backend/
│   ├── app/
│   │   ├── main.py          # FastAPI app entry point
│   │   ├── models.py        # SQLAlchemy DB models
│   │   ├── schemas.py       # Pydantic schemas
│   │   ├── database.py      # DB connection
│   │   └── routers/         # API route handlers
│   ├── requirements.txt
│   └── .env                 # ← you create this
│
└── mobile/
    ├── lib/
    │   ├── main.dart        # Flutter entry point
    │   ├── constants.dart   # ← set backend URL here
    │   ├── services/        # API + Hive offline cache
    │   ├── screens/         # UI screens
    │   ├── widgets/         # Reusable widgets
    │   └── models/          # Hive data models
    └── pubspec.yaml
```
