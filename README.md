# AgniSutra

**Smart India Hackathon Submission Project**

AgniSutra is an AI-powered smart agriculture platform that helps farmers improve crop decisions using **IoT sensor data, satellite insights, disease detection, weather context, and multilingual advisory support**.

## Problem We Address

Farmers often make critical crop decisions with delayed, fragmented, or unavailable field intelligence. AgniSutra unifies real-time farm data and AI-driven recommendations to support timely, data-backed actions.

## Core Features

- **IoT-based field monitoring** (moisture, temperature, humidity, NPK)
- **Real-time alerting** over WebSockets for critical field conditions
- **AI disease detection** from crop images (CNN + GPT fallback + RAG-based advisory)
- **Yield and fertilizer recommendation workflows**
- **Krishi Saathi assistant** for contextual advisory
- **Satellite/NDVI integration** for crop-health-aware insights
- **Authentication and farmer profile management**
- **Offline-first support in mobile app (Hive caching)**
- **Multilingual interface support**

## High-Level Architecture

- **Backend:** FastAPI + SQLAlchemy + PostgreSQL
- **Web App:** Next.js (React)
- **Mobile App:** Flutter
- **AI/ML Stack:** TensorFlow/Keras, CatBoost/Scikit-learn, LangChain, FAISS, OpenAI integration
- **Data Inputs:** IoT device payloads, satellite signals, user-entered agronomic data

## Repository Structure

```text
.
├── backend/                # FastAPI APIs, DB models, ML/LLM integration
├── frontend/               # Next.js web interface
├── mobile/                 # Flutter mobile application
├── API_DOCUMENTATION.md    # API endpoint reference
├── DB_SCHEMA.md            # Database schema overview
├── INTEGRATION_GUIDE.md    # Frontend/IoT integration guide
├── SETUP.md                # Detailed setup instructions
└── judge_evidence/         # Benchmark and model evidence artifacts
```

## Quick Start

### 1) Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Backend docs: `http://localhost:8000/docs`

### 2) Web Frontend

```bash
cd frontend
pnpm install
pnpm dev
```

Web app runs at: `http://localhost:3000`

### 3) Mobile App

```bash
cd mobile
flutter pub get
flutter run
```

Set backend URL in `mobile/lib/constants.dart` to your local machine IP for physical devices.

## Evidence for Evaluation

Model/training evidence is available in:

- `judge_evidence/1_learning_curve.png`
- `judge_evidence/3_error_dist.png`
- `judge_evidence/4_benchmark.png`
- `judge_evidence/5_shap_explanation.png`
- `judge_evidence/final_training_data.csv`

## Documentation Index

- Setup Guide: [`SETUP.md`](./SETUP.md)
- Integration Guide: [`INTEGRATION_GUIDE.md`](./INTEGRATION_GUIDE.md)
- API Documentation: [`API_DOCUMENTATION.md`](./API_DOCUMENTATION.md)
- Database Schema: [`DB_SCHEMA.md`](./DB_SCHEMA.md)

## Submission Note

This repository represents the working prototype and integration baseline prepared for Smart India Hackathon evaluation.
