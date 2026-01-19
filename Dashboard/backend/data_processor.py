"""
Data processor for ML-Lite CSV files
Calculates performance metrics from signal data
"""
import pandas as pd
import numpy as np
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from models import TierMetrics, OverallMetrics, EquityPoint, TradeRecord

class DataProcessor:
    """Process ML-Lite CSV data and calculate metrics"""
    
    def __init__(self, csv_path: Path):
        self.csv_path = csv_path
        self.df = None
        self.load_data()
    
    def load_data(self) -> None:
        """Load CSV file into DataFrame"""
        try:
            self.df = pd.read_csv(self.csv_path)
            print(f"Loaded {len(self.df)} signals from {self.csv_path.name}")
        except Exception as e:
            print(f"Error loading CSV: {e}")
            self.df = pd.DataFrame()
    
    def reload(self) -> None:
        """Reload data from CSV"""
        self.load_data()
    
    def calculate_tier_metrics(self, tier_df: pd.DataFrame) -> TierMetrics:
        """Calculate metrics for a specific tier"""
        if tier_df.empty:
            return TierMetrics()
        
        # Get completed trades only
        completed = tier_df[tier_df['Outcome'].notna()]
        
        # Count outcomes
        wins = len(completed[completed['Outcome'] == 'WIN'])
        losses = len(completed[completed['Outcome'] == 'LOSS'])
        breakevens = len(completed[completed['Outcome'] == 'BREAKEVEN'])
        
        # Calculate P/L
        profit_trades = completed[completed['ProfitPips'] > 0]
        loss_trades = completed[completed['ProfitPips'] < 0]
        
        total_profit = profit_trades['ProfitPips'].sum() if len(profit_trades) > 0 else 0
        total_loss = abs(loss_trades['ProfitPips'].sum()) if len(loss_trades) > 0 else 0
        net_pips = total_profit - total_loss
        
        # Win rate
        total_trades = wins + losses
        win_rate = wins / total_trades if total_trades > 0 else 0
        
        # Profit factor
        profit_factor = total_profit / total_loss if total_loss > 0 else (999 if total_profit > 0 else 0)
        
        # Averages
        avg_win = total_profit / wins if wins > 0 else 0
        avg_loss = total_loss / losses if losses > 0 else 0
        
        # Expectancy
        loss_rate = 1.0 - win_rate
        expectancy = (win_rate * avg_win) - (loss_rate * avg_loss)
        
        # Largest win/loss
        largest_win = profit_trades['ProfitPips'].max() if len(profit_trades) > 0 else 0
        largest_loss = abs(loss_trades['ProfitPips'].min()) if len(loss_trades) > 0 else 0
        
        return TierMetrics(
            signals_generated=len(tier_df),
            signals_taken=len(completed),
            signals_skipped=len(tier_df) - len(completed),
            wins=wins,
            losses=losses,
            breakevens=breakevens,
            win_rate=win_rate,
            profit_factor=profit_factor,
            total_profit=total_profit,
            total_loss=total_loss,
            net_pips=net_pips,
            avg_win=avg_win,
            avg_loss=avg_loss,
            expectancy=expectancy,
            largest_win=largest_win,
            largest_loss=largest_loss
        )
    
    def get_overall_metrics(self) -> OverallMetrics:
        """Calculate overall metrics"""
        if self.df.empty:
            return OverallMetrics(
                timestamp=datetime.now(),
                profit_factor=0,
                win_rate=0,
                total_signals=0,
                total_trades=0,
                total_pips=0,
                max_drawdown=0,
                current_drawdown=0,
                take_rate=0
            )
        
        completed = self.df[self.df['Outcome'].notna()]
        
        wins = len(completed[completed['Outcome'] == 'WIN'])
        losses = len(completed[completed['Outcome'] == 'LOSS'])
        total_trades = wins + losses
        
        win_rate = wins / total_trades if total_trades > 0 else 0
        
        # Calculate P/L
        total_pips = completed['ProfitPips'].sum() if len(completed) > 0 else 0
        
        profit_trades = completed[completed['ProfitPips'] > 0]
        loss_trades = completed[completed['ProfitPips'] < 0]
        
        total_profit = profit_trades['ProfitPips'].sum() if len(profit_trades) > 0 else 0
        total_loss = abs(loss_trades['ProfitPips'].sum()) if len(loss_trades) > 0 else 0
        
        profit_factor = total_profit / total_loss if total_loss > 0 else 0
        
        # Drawdown calculation (simplified)
        if len(completed) > 0:
            equity = completed['ProfitPips'].cumsum()
            peak = equity.expanding().max()
            drawdown = peak - equity
            max_drawdown = drawdown.max()
            current_drawdown = drawdown.iloc[-1] if len(drawdown) > 0 else 0
        else:
            max_drawdown = 0
            current_drawdown = 0
        
        # Take rate
        take_rate = len(completed) / len(self.df) if len(self.df) > 0 else 0
        
        return OverallMetrics(
            timestamp=datetime.now(),
            profit_factor=profit_factor,
            win_rate=win_rate,
            total_signals=len(self.df),
            total_trades=total_trades,
            total_pips=total_pips,
            max_drawdown=max_drawdown,
            current_drawdown=current_drawdown,
            take_rate=take_rate
        )
    
    def get_tier_data(self) -> Dict[str, TierMetrics]:
        """Get metrics for all tiers"""
        if self.df.empty:
            return {
                'high': TierMetrics(),
                'medium': TierMetrics(),
                'low': TierMetrics()
            }
        
        high = self.df[self.df['Score'] >= 0.70]
        medium = self.df[(self.df['Score'] >= 0.50) & (self.df['Score'] < 0.70)]
        low = self.df[self.df['Score'] < 0.50]
        
        return {
            'high': self.calculate_tier_metrics(high),
            'medium': self.calculate_tier_metrics(medium),
            'low': self.calculate_tier_metrics(low)
        }
    
    def check_calibration(self, tiers: Dict[str, TierMetrics]) -> tuple[bool, float]:
        """Check if high scores win more"""
        high_wr = tiers['high'].win_rate
        med_wr = tiers['medium'].win_rate
        
        # Need minimum data
        if tiers['high'].wins + tiers['high'].losses < 5:
            return True, 100.0
        
        is_calibrated = high_wr > med_wr
        score = ((high_wr - med_wr) / high_wr * 100) if high_wr > 0 else 0
        
        return is_calibrated, score
    
    def get_equity_curve(self, days: int = 7) -> List[EquityPoint]:
        """Get equity curve data"""
        if self.df.empty:
            return []
        
        completed = self.df[self.df['Outcome'].notna()].copy()
        if completed.empty:
            return []
        
        # Filter by date
        cutoff = datetime.now() - timedelta(days=days)
        completed['Timestamp'] = pd.to_datetime(completed['Timestamp'])
        completed = completed[completed['Timestamp'] >= cutoff]
        
        # Calculate cumulative equity
        completed = completed.sort_values('Timestamp')
        completed['CumulativePips'] = completed['ProfitPips'].cumsum()
        
        # Convert to EquityPoint list
        points = []
        for _, row in completed.iterrows():
            points.append(EquityPoint(
                timestamp=row['Timestamp'],
                equity=row['CumulativePips'],
                cumulative_pips=row['CumulativePips']
            ))
        
        return points
    
    def get_recent_trades(self, limit: int = 20) -> List[TradeRecord]:
        """Get recent trade records"""
        if self.df.empty:
            return []
        
        recent = self.df.tail(limit).copy()
        recent['Timestamp'] = pd.to_datetime(recent['Timestamp'])
        
        trades = []
        for _, row in recent.iterrows():
            trades.append(TradeRecord(
                trade_id=row['TradeID'],
                timestamp=row['Timestamp'],
                symbol=row['Symbol'],
                direction=row['Direction'],
                score=row['Score'],
                entry_price=row['EntryPrice'],
                stop_loss=row['StopLoss'],
                take_profit=row['TakeProfit'],
                outcome=row.get('Outcome'),
                profit_pips=row.get('ProfitPips'),
                mfe=row.get('MFE'),
                mae=row.get('MAE')
            ))
        
        return trades
