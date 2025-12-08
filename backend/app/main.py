from contextlib import asynccontextmanager
import pickle
import joblib
import tensorflow as tf
from tensorflow.keras.layers import InputLayer
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from .scheduler import check_conditions_job

from .routers import auth, iot, krishi_saathi, disease
from .ml import ml_models
from .manager import manager

# Fix for Keras Version Mismatch (batch_shape vs batch_input_shape)
class PatchedInputLayer(InputLayer):
    def __init__(self, *args, **kwargs):
        if 'batch_shape' in kwargs:
            kwargs['batch_input_shape'] = kwargs.pop('batch_shape')
        super().__init__(*args, **kwargs)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Load the ML model
    try:
        import os
        current_dir = os.path.dirname(os.path.abspath(__file__))
        
        # 1. Load Keras Model (Fertilizer Recommender)
        model_path = os.path.join(current_dir, "final_model.keras")
        if os.path.exists(model_path):
            # compile=False is often safer for inference-only loading to avoid optimizer version mismatches
            # custom_objects={'InputLayer': PatchedInputLayer} handles the version mismatch
            ml_models["fertilizer_model"] = tf.keras.models.load_model(
                model_path, 
                compile=False,
                custom_objects={'InputLayer': PatchedInputLayer}
            )
            print(f"✅ Keras Fertilizer Model loaded successfully from {model_path}")
        else:
            print(f"❌ Model file not found at {model_path}")
            
        # 2. Load Preprocessor (Required for Keras model)
        # Look in current dir first, then project root
        preprocessor_path = os.path.join(current_dir, "dl_preprocessor.joblib")
        if not os.path.exists(preprocessor_path):
             # Fallback to project root (../../dl_preprocessor.joblib)
             preprocessor_path = os.path.abspath(os.path.join(current_dir, "../../dl_preprocessor.joblib"))
        
        if os.path.exists(preprocessor_path):
            ml_models["preprocessor"] = joblib.load(preprocessor_path)
            print(f"✅ Preprocessor loaded successfully from {preprocessor_path}")
        else:
            print(f"❌ Preprocessor file not found at {preprocessor_path}")
            ml_models["preprocessor"] = None
            
    except Exception as e:
        print(f"Error loading ML model: {e}")
        ml_models["fertilizer_model"] = None
        ml_models["preprocessor"] = None
    
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

