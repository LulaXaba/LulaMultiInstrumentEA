"""
ML-Lite Dashboard Backend - FastAPI Server
Serves performance metrics from ML-Lite CSV data
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pathlib import Path
from datetime import datetime
import uvicorn

from config import config
from models import (
    MetricsResponse, EquityCurveResponse, RecentTradesResponse,
    OverallMetrics, EquityPoint
)
from data_processor import DataProcessor

# Initialize FastAPI app
app = FastAPI(
    title="ML-Lite Dashboard API",
    description="Performance metrics API for ML-Lite trading system",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global data processor
processor = None
_initialized = False

def ensure_processor():
    """Lazy initialization - load processor on first use"""
    global processor, _initialized
    if not _initialized:
        _initialized = True
        try:
            print("Starting backend initialization...", flush=True)
            csv_path = config.get_latest_csv()
            print(f"Found CSV: {csv_path}", flush=True)
            processor = DataProcessor(csv_path)
            print(f"Dashboard backend started", flush=True)
            print(f"Monitoring: {csv_path}", flush=True)
        except Exception as e:
            import traceback
            print(f"Warning: {e}", flush=True)
            print(f"Traceback: {traceback.format_exc()}", flush=True)
            print("Continuing without data...", flush=True)

@app.get("/")
async def root():
    """Root endpoint - API info"""
    return {
        "name": "ML-Lite Dashboard API",
        "version": "1.0.0",
        "status": "online",
        "timestamp": datetime.now().isoformat()
    }

@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    ensure_processor()  # Lazy init
    has_data = processor is not None and not processor.df.empty
    
    return {
        "status": "healthy",
        "has_data": has_data,
        "data_points": len(processor.df) if has_data else 0,
        "timestamp": datetime.now().isoformat()
    }

@app.get("/api/metrics", response_model=MetricsResponse)
async def get_metrics():
    """Get current performance metrics"""
    ensure_processor()  # Lazy init
    if processor is None or processor.df.empty:
        raise HTTPException(status_code=503, detail="No data available")
    
    # Reload data to get latest
    processor.reload()
    
    # Calculate metrics
    overall = processor.get_overall_metrics()
    tiers = processor.get_tier_data()
    is_calibrated, calib_score = processor.check_calibration(tiers)
    
    return MetricsResponse(
        overall=overall,
        high_tier=tiers['high'],
        medium_tier=tiers['medium'],
        low_tier=tiers['low'],
        calibration_score=calib_score,
        is_calibrated=is_calibrated
    )

@app.get("/api/equity-curve", response_model=EquityCurveResponse)
async def get_equity_curve(days: int = 7):
    """Get equity curve data"""
    if processor is None or processor.df.empty:
        raise HTTPException(status_code=503, detail="No data available")
    
    processor.reload()
    
    points = processor.get_equity_curve(days)
    
    if not points:
        return EquityCurveResponse(
           data=[],
            peak_equity=0,
            current_equity=0,
            max_drawdown=0,
            period_days=days
        )
    
    equities = [p.equity for p in points]
    peak = max(equities)
    current = equities[-1] if equities else 0
    
    # Calculate max drawdown
    max_dd = 0
    peak_so_far = equities[0] if equities else 0
    for equity in equities:
        if equity > peak_so_far:
            peak_so_far = equity
        dd = peak_so_far - equity
        if dd > max_dd:
            max_dd = dd
    
    return EquityCurveResponse(
        data=points,
        peak_equity=peak,
        current_equity=current,
        max_drawdown=max_dd,
        period_days=days
    )

@app.get("/api/tier-analysis")
async def get_tier_analysis():
    """Get tier breakdown"""
    if processor is None or processor.df.empty:
        raise HTTPException(status_code=503, detail="No data available")
    
    processor.reload()
    tiers = processor.get_tier_data()
    
    return {
        "high": tiers['high'].dict(),
        "medium": tiers['medium'].dict(),
        "low": tiers['low'].dict()
    }

@app.get("/api/trades/recent", response_model=RecentTradesResponse)
async def get_recent_trades(limit: int = 20):
    """Get recent trade records"""
    if processor is None or processor.df.empty:
        raise HTTPException(status_code=503, detail="No data available")
    
    processor.reload()
    trades = processor.get_recent_trades(limit)
    
    return RecentTradesResponse(
        trades=trades,
        count=len(trades)
    )

@app.post("/api/reload")
async def reload_data():
    """Manually reload data from CSV"""
    if processor is None:
        raise HTTPException(status_code=503, detail="Processor not initialized")
    
    processor.reload()
    
    return {
        "status": "success",
        "message": "Data reloaded",
        "records": len(processor.df)
    }

if __name__ == "__main__":
    print("Starting ML-Lite Dashboard Backend...")
    print(f"API URL: http://{config.HOST}:{config.PORT}")
    print(f"ML Data Path: {config.ML_DATA_PATH}")
    print(f"CORS Origins: {config.CORS_ORIGINS}")
    print()
    
    uvicorn.run(
        "main:app",
        host=config.HOST,
        port=config.PORT,
        reload=config.RELOAD,
        log_level="info"
    )
