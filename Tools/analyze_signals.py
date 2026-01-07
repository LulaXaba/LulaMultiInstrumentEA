"""
ML-Lite CSV Analyzer
Analyzes signal CSV files to provide insights for threshold optimization.

Usage:
    python analyze_signals.py signals_2026-01.csv

Features:
    - Score distribution analysis
    - Win rate by score tier
    - Threshold recommendations
    - Performance metrics
    - Data quality checks
"""

import pandas as pd
import sys
from pathlib import Path

def load_csv(filepath):
    """Load and validate CSV file."""
    try:
        df = pd.read_csv(filepath)
        print(f"✅ Loaded {len(df)} signals from {filepath}")
        return df
    except Exception as e:
        print(f"❌ Error loading CSV: {e}")
        sys.exit(1)

def analyze_score_distribution(df):
    """Analyze score distribution across tiers."""
    print("\n" + "="*60)
    print("SCORE DISTRIBUTION ANALYSIS")
    print("="*60)
    
    # Define tiers
    high = df[df['OverallScore'] >= 0.70]
    medium = df[(df['OverallScore'] >= 0.50) & (df['OverallScore'] < 0.70)]
    low = df[df['OverallScore'] < 0.50]
    
    print(f"\nHigh Tier (>= 0.70):   {len(high):4d} signals ({len(high)/len(df)*100:5.1f}%)")
    print(f"Medium Tier (0.50-0.69): {len(medium):4d} signals ({len(medium)/len(df)*100:5.1f}%)")
    print(f"Low Tier (< 0.50):     {len(low):4d} signals ({len(low)/len(df)*100:5.1f}%)")
    
    # Score statistics
    print(f"\nScore Statistics:")
    print(f"  Mean:   {df['OverallScore'].mean():.4f}")
    print(f"  Median: {df['OverallScore'].median():.4f}")
    print(f"  Std:    {df['OverallScore'].std():.4f}")
    print(f"  Min:    {df['OverallScore'].min():.4f}")
    print(f"  Max:    {df['OverallScore'].max():.4f}")
    
    return high, medium, low

def analyze_win_rates(df):
    """Calculate win rates by score range."""
    print("\n" + "="*60)
    print("WIN RATE BY SCORE RANGE")
    print("="*60)
    
    # Filter only completed trades
    completed = df[df['ActualOutcome'].notna()]
    
    if len(completed) == 0:
        print("\n⚠️  No completed trades yet")
        return
    
    print(f"\nCompleted trades: {len(completed)}")
    
    # Define score ranges
    ranges = [
        (0.00, 0.50, "Very Low"),
        (0.50, 0.60, "Low"),
        (0.60, 0.70, "Medium"),
        (0.70, 0.80, "High"),
        (0.80, 1.00, "Very High")
    ]
    
    print(f"\n{'Range':<15} {'Count':>6} {'Wins':>6} {'Win Rate':>10} {'Avg P/L':>10}")
    print("-" * 60)
    
    for min_score, max_score, label in ranges:
        range_df = completed[(completed['OverallScore'] >= min_score) & 
                            (completed['OverallScore'] < max_score)]
        
        if len(range_df) == 0:
            continue
        
        wins = len(range_df[range_df['ActualOutcome'] == 'WIN'])
        win_rate = wins / len(range_df) * 100
        avg_pl = range_df['ProfitPips'].mean()
        
        print(f"{label:<15} {len(range_df):6d} {wins:6d} {win_rate:9.1f}% {avg_pl:+9.1f}")

def recommend_threshold(df):
    """Recommend optimal threshold based on data."""
    print("\n" + "="*60)
    print("THRESHOLD RECOMMENDATIONS")
    print("="*60)
    
    completed = df[df['ActualOutcome'].notna()]
    
    if len(completed) < 20:
        print("\n⚠️  Not enough data for recommendations (need 20+ trades)")
        return
    
    print(f"\nTesting thresholds from 0.50 to 0.80...")
    print(f"\n{'Threshold':>10} {'Signals':>8} {'Win Rate':>10} {'Grade':>8}")
    print("-" * 40)
    
    best_threshold = 0.50
    best_score = 0
    
    for threshold in [0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80]:
        filtered = completed[completed['OverallScore'] >= threshold]
        
        if len(filtered) < 5:
            continue
        
        wins = len(filtered[filtered['ActualOutcome'] == 'WIN'])
        win_rate = wins / len(filtered) * 100 if len(filtered) > 0 else 0
        
        # Scoring: balance win rate and trade count
        score = win_rate * (len(filtered) / len(completed))
        
        if score > best_score:
            best_score = score
            best_threshold = threshold
        
        grade = "🌟" if threshold == best_threshold else "  "
        print(f"{threshold:10.2f} {len(filtered):8d} {win_rate:9.1f}% {grade:>8}")
    
    print(f"\n✅ Recommended threshold: {best_threshold:.2f}")
    print(f"   Expected win rate: Based on {len(completed[completed['OverallScore'] >= best_threshold])} trades")

def check_calibration(df):
    """Check if high scores actually win more."""
    print("\n" + "="*60)
    print("CALIBRATION CHECK")
    print("="*60)
    
    completed = df[df['ActualOutcome'].notna()]
    
    if len(completed) < 20:
        print("\n⚠️  Not enough data")
        return
    
    # Compare tiers
    high = completed[completed['OverallScore'] >= 0.70]
    medium = completed[(completed['OverallScore'] >= 0.50) & 
                      (completed['OverallScore'] < 0.70)]
    
    if len(high) >= 5 and len(medium) >= 5:
        high_wr = len(high[high['ActualOutcome'] == 'WIN']) / len(high) * 100
        med_wr = len(medium[medium['ActualOutcome'] == 'WIN']) / len(medium) * 100
        
        print(f"\nHigh Tier Win Rate:   {high_wr:5.1f}% ({len(high)} trades)")
        print(f"Medium Tier Win Rate: {med_wr:5.1f}% ({len(medium)} trades)")
        
        if high_wr > med_wr:
            print(f"\n✅ System is calibrated (high scores win {high_wr - med_wr:.1f}% more)")
        else:
            print(f"\n⚠️  System may need recalibration")
    else:
        print("\n⚠️  Not enough data in each tier")

def print_summary(df):
    """Print overall summary."""
    print("\n" + "="*60)
    print("SUMMARY")
    print("="*60)
    
    completed = df[df['ActualOutcome'].notna()]
    
    print(f"\nTotal Signals: {len(df)}")
    print(f"Completed Trades: {len(completed)}")
    
    if len(completed) > 0:
        wins = len(completed[completed['ActualOutcome'] == 'WIN'])
        win_rate = wins / len(completed) * 100
        avg_pl = completed['ProfitPips'].mean()
        
        print(f"Overall Win Rate: {win_rate:.1f}%")
        print(f"Average P/L: {avg_pl:+.1f} pips")
        
        if 'MFE' in completed.columns:
            print(f"Average MFE: {completed['MFE'].mean():+.1f} pips")
            print(f"Average MAE: {completed['MAE'].mean():+.1f} pips")

def main():
    if len(sys.argv) < 2:
        print("Usage: python analyze_signals.py <csv_file>")
        print("Example: python analyze_signals.py signals_2026-01.csv")
        sys.exit(1)
    
    filepath = Path(sys.argv[1])
    
    if not filepath.exists():
        print(f"❌ File not found: {filepath}")
        sys.exit(1)
    
    # Load data
    df = load_csv(filepath)
    
    # Run analyses
    analyze_score_distribution(df)
    analyze_win_rates(df)
    recommend_threshold(df)
    check_calibration(df)
    print_summary(df)
    
    print("\n" + "="*60)
    print("Analysis complete!")
    print("="*60)

if __name__ == "__main__":
    main()
