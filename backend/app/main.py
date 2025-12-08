from contextlib import asynccontextmanager
import pickle
import joblib
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from .scheduler import check_conditions_job

from .routers import auth, iot, krishi_saathi, disease
from .ml import ml_models
from .manager import manager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Load the ML model
    try:
        import os
        current_dir = os.path.dirname(os.path.abspath(__file__))
        model_path = os.path.join(current_dir, "final_yield_model_CatBoost.joblib")
        
        if os.path.exists(model_path):
            ml_models["yield_model"] = joblib.load(model_path)
            print(f"✅ CatBoost Model loaded successfully from {model_path}")
        else:
            print(f"❌ Model file not found at {model_path}")
            # Try fallback to relative path just in case
            ml_models["yield_model"] = joblib.load("app/final_yield_model_CatBoost.joblib")
            print("✅ CatBoost Model loaded successfully (fallback path).")
            
    except Exception as e:
        print(f"Error loading ML model: {e}")
        ml_models["yield_model"] = None
    
    # Start Scheduler
    scheduler = AsyncIOScheduler()
    scheduler.add_job(check_conditions_job, 'interval', minutes=0.5) # Run every 30 mins
    scheduler.start()
    print("✅ Scheduler started: Running every 30 minutes.")
    
    yield
    
    # Clean up
    scheduler.shutdown()
    ml_models.clear()

app = FastAPI(title="AgniSutra API", version="1.0.0", lifespan=lifespan)

# Mount static files
app.mount("/static", StaticFiles(directory="app/static"), name="static")

# Configure CORS - allow web frontend and common mobile emulator hosts
origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", tags=["root"])
def read_root():
    return {"message": "Welcome to AgniSutra API (app.main)"}


@app.websocket("/ws/alerts")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            await websocket.receive_text() # Keep connection open
    except WebSocketDisconnect:
        manager.disconnect(websocket)


# include routers
app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(iot.router, prefix="/iot", tags=["iot"])
app.include_router(krishi_saathi.router, prefix="/krishi-saathi", tags=["krishi-saathi"])
app.include_router(disease.router, prefix="/disease", tags=["disease"])

