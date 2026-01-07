# ML-Lite Analysis Tools

Python utilities for analyzing ML-Lite CSV data and optimizing parameters.

## Installation

```bash
pip install pandas matplotlib seaborn
```

## Tools

### 1. analyze_signals.py

Comprehensive CSV analysis for threshold optimization.

**Usage**:
```bash
python analyze_signals.py signals_2026-01.csv
```

**Features**:
- Score distribution by tier
- Win rate by score range
- Threshold recommendations
- Calibration checking
- Performance summary

**Example Output**:
```
SCORE DISTRIBUTION ANALYSIS
====================================
High Tier (>= 0.70):     45 signals (22.5%)
Medium Tier (0.50-0.69): 95 signals (47.5%)
Low Tier (< 0.50):       60 signals (30.0%)

WIN RATE BY SCORE RANGE
====================================
Range           Count   Wins  Win Rate   Avg P/L
----------------------------------------------------
Low (0.50-0.60)    35     18     51.4%    +12.3
Medium (0.60-0.70) 48     32     66.7%    +28.5
High (0.70-0.80)   28     21     75.0%    +35.2

THRESHOLD RECOMMENDATIONS
====================================
Threshold  Signals  Win Rate    Grade
----------------------------------------
     0.50      111     58.6%          
     0.55       98     62.2%          
     0.60       76     67.1%      🌟
     0.65       52     70.2%          

✅ Recommended threshold: 0.60
```

### 2. plot_distribution.py

Creates visual plots for data exploration.

**Usage**:
```bash
python plot_distribution.py signals_2026-01.csv
```

**Generates**:
- `score_distribution.png` - Histogram and box plots
- `win_rate_by_score.png` - Win rate across score ranges
- `tier_comparison.png` - Performance metrics by tier

**Requirements**:
- pandas
- matplotlib
- seaborn

### 3. compare_periods.py

Compare ML-Lite ON vs OFF performance.

**Usage**:
```bash
python compare_periods.py baseline.csv filtered.csv
```

**Compares**:
- Win rate improvement
- Profit factor change
- Drawdown reduction
- Trade count reduction
- Statistical significance

## Quick Start

1. **Collect baseline data** (1-2 weeks):
   ```
   InpMLDataCollection = true
   InpMLLiteEnabled = false
   ```

2. **Analyze baseline**:
   ```bash
   python analyze_signals.py MQL5/Files/ML_Data/signals_2026-01.csv
   ```

3. **Enable ML-Lite** with recommended threshold

4. **Visualize results**:
   ```bash
   python plot_distribution.py MQL5/Files/ML_Data/signals_2026-01.csv
   ```

5. **Compare periods**:
   ```bash
   python compare_periods.py baseline.csv filtered.csv
   ```

## Data Location

CSV files are saved in:
```
MQL5/Files/ML_Data/signals_YYYY-MM.csv
```

## Tips

- **Minimum data**: 50+ signals for reliable analysis
- **Completed trades**: Need 20+ for win rate analysis
- **Multiple symbols**: Analyze separately for best results
- **Monthly files**: Compare month-over-month performance

## Troubleshooting

**"Not enough data"**:
- Run EA for longer (2+ weeks)
- Lower score threshold to get more signals
- Check that data collection is enabled

**ModuleNotFoundError**:
```bash
pip install pandas matplotlib seaborn
```

**No completed trades**:
- Data only shows signals, not outcomes yet
- Wait for trades to close
- Check ActualOutcome column in CSV

## Examples

### Find Optimal Threshold
```bash
python analyze_signals.py signals_2026-01.csv | grep "Recommended"
```

### Generate All Visualizations
```bash
python plot_distribution.py signals_2026-01.csv
```

### Quick Win Rate Check
```bash
python analyze_signals.py signals_2026-01.csv | grep -A 10 "WIN RATE"
```

## Version

v1.0 - January 2026
