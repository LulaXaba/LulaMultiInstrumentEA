"""
Simple FastAPI Test Server for ML API Integration Testing
This mock server simulates ML model predictions for testing WebRequest functionality
"""

from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel
from typing import List, Optional
import time
import uvicorn
from datetime import datetime

app = FastAPI(
    title="ML API Test Server",
    description="Mock ML prediction API for LulaMultiInstrumentEA testing",
    version="1.0.0"
)

# Request/Response models
class PredictionRequest(BaseModel):
    symbol: str
    timeframe: str
    timestamp: int
    features: List[float]

class SignalQualityResponse(BaseModel):
    score: float
    confidence: float
    latency_ms: float
    model_version: str = "mock-1.0"

class HealthResponse(BaseModel):
    status: str
    service: str
    timestamp: str
    uptime_seconds: float

# Server start time for uptime calculation
start_time = time.time()

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "ML API Test Server is running",
        "version": "1.0.0",
        "endpoints": [
            "/health",
            "/predict/signal_quality",
            "/predict/sl_tp",
            "/predict/regime"
        ]
    }

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    return HealthResponse(
        status="healthy",
        service="ML API Test Server",
        timestamp=datetime.now().isoformat(),
        uptime_seconds=time.time() - start_time
    )

@app.post("/predict/signal_quality", response_model=SignalQualityResponse)
async def predict_signal_quality(request: Request):
    """
    Mock ML prediction for signal quality scoring
    Returns a score between 0.0 and 1.0 based on simple heuristics
    """
    request_start = time.time()
    
    # Handle both JSON body and form-encoded data (MQL5 WebRequest sends as form)
    try:
        # Try to parse as JSON first
        data = await request.json()
    except:
        # If that fails, try to get form data
        form = await request.form()
        # MQL5 sends the entire JSON as a single form key
        for key in form.keys():
            try:
                import json
                data = json.loads(key)
                break
            except:
                continue
        else:
            raise HTTPException(status_code=400, detail="Could not parse request data")
    
    # Extract fields
    symbol = data.get('symbol', 'UNKNOWN')
    timeframe = data.get('timeframe', 'UNKNOWN')
    features = data.get('features', [])
    
    # Validate features
    if len(features) == 0:
        raise HTTPException(status_code=400, detail="Features array cannot be empty")
    
    # Mock prediction logic (simple average of features for demo)
    feature_avg = sum(features) / len(features)
    
    # Normalize to 0-1 range and add some randomness
    import random
    score = min(1.0, max(0.0, feature_avg + random.uniform(-0.1, 0.1)))
    confidence = random.uniform(0.7, 0.95)
    
    latency_ms = (time.time() - request_start) * 1000
    
    print(f"[{datetime.now()}] Signal Quality Prediction: {symbol} {timeframe}")
    print(f"  Features: {len(features)} dims, Score: {score:.4f}, Confidence: {confidence:.4f}")
    
    return SignalQualityResponse(
        score=score,
        confidence=confidence,
        latency_ms=latency_ms
    )

@app.post("/predict/sl_tp")
async def predict_sl_tp(request: PredictionRequest):
    """
    Mock prediction for optimal Stop-Loss and Take-Profit levels
    """
    import random
    
    # Mock SL/TP prediction
    sl_pips = random.uniform(20, 80)
    tp_pips = random.uniform(40, 150)
    risk_reward = tp_pips / sl_pips
    
    return {
        "stop_loss_pips": round(sl_pips, 1),
        "take_profit_pips": round(tp_pips, 1),
        "risk_reward_ratio": round(risk_reward, 2),
        "confidence": random.uniform(0.70, 0.90),
        "model_version": "mock-sltp-1.0"
    }

@app.post("/predict/regime")
async def predict_market_regime(request: PredictionRequest):
    """
    Mock prediction for market regime classification
    """
    import random
    
    regimes = ["TRENDING_BULL", "TRENDING_BEAR", "RANGING", "HIGH_VOLATILITY", "BREAKOUT"]
    probabilities = [random.uniform(0, 1) for _ in regimes]
    total = sum(probabilities)
    probabilities = [p / total for p in probabilities]
    
    max_idx = probabilities.index(max(probabilities))
    
    return {
        "regime": regimes[max_idx],
        "probabilities": {
            regime: round(prob, 4) 
            for regime, prob in zip(regimes, probabilities)
        },
        "confidence": round(max(probabilities), 4),
        "model_version": "mock-regime-1.0"
    }

@app.post("/predict/position_size")
async def predict_position_size(request: PredictionRequest):
    """
    Mock prediction for optimal position sizing
    """
    import random
    
    # Risk multiplier between 0.5x and 2.0x
    multiplier = random.uniform(0.5, 2.0)
    
    return {
        "risk_multiplier": round(multiplier, 2),
        "explanation": "Based on signal confidence and market conditions",
        "confidence": random.uniform(0.65, 0.85),
        "model_version": "mock-position-1.0"
    }

@app.post("/collect_data")
async def collect_training_data(request: PredictionRequest):
    """
    Endpoint to collect training data (in production, this would save to database)
    """
    print(f"[{datetime.now()}] Data collected: {request.symbol} {request.timeframe}")
    print(f"  Features: {len(request.features)} dimensions")
    
    return {
        "status": "success",
        "message": "Training data recorded",
        "record_id": int(time.time() * 1000)
    }

# Utility endpoints for testing

@app.get("/delay/{seconds}")
async def delay_endpoint(seconds: int):
    """Endpoint with configurable delay for timeout testing"""
    if seconds > 10:
        raise HTTPException(status_code=400, detail="Max delay is 10 seconds")
    
    time.sleep(seconds)
    return {"delayed_seconds": seconds, "message": "Delay complete"}

@app.get("/status/{code}")
async def custom_status_code(code: int):
    """Return custom HTTP status code for error testing"""
    from fastapi import Response
    return Response(
        content=f'{{"status": {code}, "test": "custom_status"}}',
        status_code=code,
        media_type="application/json"
    )

if __name__ == "__main__":
    print("=" * 60)
    print("ML API Test Server")
    print("=" * 60)
    print("Starting FastAPI server on http://localhost:8000")
    print("\nAvailable endpoints:")
    print("  GET  /health - Health check")
    print("  POST /predict/signal_quality - Signal quality scoring")
    print("  POST /predict/sl_tp - SL/TP optimization")
    print("  POST /predict/regime - Market regime classification")
    print("  POST /predict/position_size - Position sizing")
    print("\nTest endpoints:")
    print("  GET  /delay/{seconds} - Delayed response")
    print("  GET  /status/{code} - Custom HTTP status code")
    print("\nAPI Documentation:")
    print("  http://localhost:8000/docs")
    print("=" * 60)
    print()
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )
