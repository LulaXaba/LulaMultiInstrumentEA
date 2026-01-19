"""
Configuration for ML-Lite Dashboard Backend
"""
import os
from pathlib import Path

class Config:
    """Application configuration"""
    
    # Server
    HOST = "127.0.0.1"  # localhost only for security
    PORT = 8000
    RELOAD = False  # Disable reload for proper initialization
    
    # Data paths
    BASE_DIR = Path(__file__).parent
    
    # Default ML_Data path (adjust to your MT5 installation)
    ML_DATA_PATH = Path(os.getenv(
        "ML_DATA_PATH",
        r"C:\Users\Admin\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Files\ML_Data"
    ))
    
    # API settings
    API_PREFIX = "/api"
    CORS_ORIGINS = [
        "http://localhost:3000",  # Next.js dev server
        "http://127.0.0.1:3000",
        "http://localhost:3001",  # Next.js dev server (alternate port)
        "http://127.0.0.1:3001",
    ]
    
    # Data refresh
    CACHE_TTL = 60  # seconds
    FILE_WATCH_INTERVAL = 5  # seconds
    
    # Metrics
    DEFAULT_LOOKBACK_DAYS = 7
    MAX_RECENT_TRADES = 50
    
    @classmethod
    def get_latest_csv(cls) -> Path:
        """Get the most recent signals CSV file"""
        if not cls.ML_DATA_PATH.exists():
            raise FileNotFoundError(f"ML_Data directory not found: {cls.ML_DATA_PATH}")
        
        csv_files = list(cls.ML_DATA_PATH.glob("signals_*.csv"))
        if not csv_files:
            raise FileNotFoundError("No signals CSV files found")
        
        # Return newest file
        return max(csv_files, key=lambda p: p.stat().st_mtime)

config = Config()
