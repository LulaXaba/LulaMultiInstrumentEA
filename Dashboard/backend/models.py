"""
Pydantic models for ML-Lite Dashboard API
"""
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

class TierMetrics(BaseModel):
    """Performance metrics for a score tier"""
    signals_generated: int = 0
    signals_taken: int = 0
    signals_skipped: int = 0
    wins: int = 0
    losses: int = 0
    breakevens: int = 0
    win_rate: float = 0.0
    profit_factor: float = 0.0
    total_profit: float = 0.0
    total_loss: float = 0.0
    net_pips: float = 0.0
    avg_win: float = 0.0
    avg_loss: float = 0.0
    expectancy: float = 0.0
    largest_win: float = 0.0
    largest_loss: float = 0.0

class OverallMetrics(BaseModel):
    """Overall performance metrics"""
    timestamp: datetime
    profit_factor: float
    sharpe_ratio: float = 0.0
    win_rate: float
    total_signals: int
    total_trades: int
    total_pips: float
    max_drawdown: float
    current_drawdown: float
    take_rate: float

class MetricsResponse(BaseModel):
    """Complete metrics response"""
    overall: OverallMetrics
    high_tier: TierMetrics
    medium_tier: TierMetrics
    low_tier: TierMetrics
    calibration_score: float
    is_calibrated: bool

class EquityPoint(BaseModel):
    """Single point on equity curve"""
    timestamp: datetime
    equity: float
    cumulative_pips: float

class EquityCurveResponse(BaseModel):
    """Equity curve data"""
    data: List[EquityPoint]
    peak_equity: float
    current_equity: float
    max_drawdown: float
    period_days: int

class TradeRecord(BaseModel):
    """Individual trade record"""
    trade_id: str
    timestamp: datetime
    symbol: str
    direction: str
    score: float
    entry_price: float
    stop_loss: float
    take_profit: float
    outcome: Optional[str] = None
    profit_pips: Optional[float] = None
    mfe: Optional[float] = None
    mae: Optional[float] = None

class RecentTradesResponse(BaseModel):
    """Recent trades list"""
    trades: List[TradeRecord]
    count: int
