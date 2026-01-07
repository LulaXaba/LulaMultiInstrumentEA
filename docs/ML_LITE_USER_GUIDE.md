# ML-Lite User Guide

**Version**: 1.0  
**Last Updated**: January 7, 2026  
**Phase**: Phase 0 - ML-Lite Foundation

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Parameters Reference](#parameters-reference)
4. [How It Works](#how-it-works)
5. [Tuning Guide](#tuning-guide)
6. [Performance Dashboards](#performance-dashboards)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)
9. [FAQ](#faq)

---

## Overview

### What is ML-Lite?

ML-Lite is an intelligent signal filtering system that improves your EA's performance by:
- **Scoring every signal** (0.0-1.0) based on 20+ factors
- **Filtering low-quality signals** below your threshold
- **Scaling risk** for high-confidence trades
- **Tracking performance** by score tier
- **Providing dashboards** every 6 hours

### Key Benefits

✅ **Higher Win Rate** - Filter out low-quality signals  
✅ **Lower Drawdown** - Take only high-confidence trades  
✅ **Better Profit Factor** - Quality over quantity  
✅ **Data-Driven** - Track what scores actually work  
✅ **Adaptive Risk** - Scale lot size by confidence

### System Architecture

```
Trading Signal Detected
    ↓
Score Signal (0.0-1.0)
    ↓
Check Score >= Threshold? ← ML-Lite Filtering
    ├─ NO → Skip Trade (Logged but not executed)
    └─ YES → Continue
        ↓
    Scale Risk (Optional) ← ML-Lite Risk Scaling
        ↓
    Execute Trade
        ↓
    Track Performance ← ML-Lite Analytics
```

---

## Quick Start

### Step 1: Enable Data Collection Only (Week 1)

**Recommended for first week** - Collect baseline data without filtering.

```
// In EA Parameters
InpMLDataCollection = true        // Enable CSV logging
InpMLLiteEnabled = false          // Disable filtering (baseline)
```

**What happens**:
- All signals are scored and logged to CSV
- NO filtering applied
- EA trades normally
- Builds baseline performance data

**Run for**: 7 days minimum

### Step 2: Enable ML-Lite Filtering (Week 2)

After collecting baseline, enable filtering:

```
InpMLDataCollection = true        // Keep logging
InpMLLiteEnabled = true           // Enable filtering
InpMLScoreThreshold = 0.60        // Default threshold
InpMLRiskScaling = false          // No risk scaling yet
```

**What happens**:
- Signals scored as before
- **Signals < 0.60 are filtered** (not executed)
- Only high-quality signals taken
- Performance tracked by tier

**Run for**: 7 days minimum

### Step 3: Compare Results

After 2 weeks, compare:
- **Baseline** (week 1): All signals, no filtering
- **ML-Lite** (week 2): Filtered signals

**Check dashboards for**:
- Win rate improvement
- Drawdown reduction
- Profit factor increase
- Number of filtered signals

### Step 4: Optimize (Optional)

If results are good, experiment with:
- **Risk Scaling**: `InpMLRiskScaling = true`
- **Threshold Adjustment**: Try 0.65 or 0.55
- **Risk Multipliers**: Adjust high/medium multipliers

---

## Parameters Reference

### ML Data Collection

#### `InpMLDataCollection`
- **Type**: Boolean
- **Default**: `true`
- **Description**: Enables CSV logging of all signals
- **When to disable**: Never (unless you don't want data)
- **Impact**: Creates CSV files in `MQL5/Files/ML_Data/`

#### `InpMLDataPath`
- **Type**: String
- **Default**: `"ML_Data"`
- **Description**: Directory name for CSV files
- **When to change**: If you want custom folder structure
- **Impact**: Changes where files are saved

#### `InpMLMaxFileSize`
- **Type**: Integer (MB)
- **Default**: `50`
- **Description**: Max size before file rotation
- **When to change**: If files get too large
- **Impact**: Larger = fewer files, smaller = more files

#### `InpMLFlushInterval`
- **Type**: Integer (minutes)
- **Default**: `60`
- **Description**: How often to flush data to disk
- **When to change**: If concerned about data loss
- **Impact**: Lower = safer but more disk I/O

### ML-Lite Filtering

#### `InpMLLiteEnabled`
- **Type**: Boolean
- **Default**: `false`
- **Description**: Enables score-based filtering
- **When to enable**: After 1 week of baseline data
- **Impact**: ⚠️ **Filters trades** - only takes signals >= threshold

#### `InpMLScoreThreshold`
- **Type**: Double (0.0-1.0)
- **Default**: `0.60`
- **Description**: Minimum score required to take trade
- **Tuning Range**: 0.50 (aggressive) to 0.80 (conservative)
- **Impact**: 
  - **Higher** = Fewer trades, higher quality
  - **Lower** = More trades, lower average quality

**Threshold Guidelines**:
- **0.50-0.55**: Aggressive (most signals pass)
- **0.60-0.65**: Balanced (default)
- **0.70-0.75**: Conservative (high quality only)
- **0.80+**: Very conservative (rare trades)

#### `InpMLRiskScaling`
- **Type**: Boolean
- **Default**: `false`
- **Description**: Enables adaptive lot sizing by score
- **When to enable**: After confirming filtering works
- **Impact**: Increases lot size for high scores

#### `InpMLHighScoreMultiplier`
- **Type**: Double
- **Default**: `1.5`
- **Description**: Lot size multiplier for scores >= 0.80
- **Safe Range**: 1.2 to 2.0
- **Impact**: Example: 1.5x means 0.10 lot becomes 0.15 lot

#### `InpMLMediumScoreMultiplier`
- **Type**: Double
- **Default**: `1.2`
- **Description**: Lot size multiplier for scores >= 0.65
- **Safe Range**: 1.1 to 1.5
- **Impact**: Example: 1.2x means 0.10 lot becomes 0.12 lot

---

## How It Works

### Signal Scoring System

Every signal is evaluated across **5 categories** with **20 factors**:

#### 1. Trend Alignment (25% weight)
- HTF/MTF trend agreement
- ADX strength
- Trend duration
- MA alignment

#### 2. Technical Confirmation (25% weight)
- RSI position
- MACD confirmation
- Candlestick patterns
- Support/resistance proximity

#### 3. Market Context (20% weight)
- Volatility regime
- Trading session
- Time of day
- Spread conditions

#### 4. Risk/Reward (15% weight)
- SL/TP ratio
- Distance to key levels
- ATR-based sizing

#### 5. Historical Pattern (15% weight)
- Similar setup success rate
- Recent pattern performance

**Final Score** = Weighted average of all factors (0.0-1.0)

### Score Tiers

Signals are categorized into 3 tiers:

**High Tier** (Score >= 0.70):
- Strongest signals
- Highest expected win rate
- Eligible for risk scaling

**Medium Tier** (0.50 <= Score < 0.70):
- Good signals
- Acceptable quality
- Standard risk

**Low Tier** (Score < 0.50):
- Weak signals
- Usually filtered out
- Not recommended

### Filtering Logic

```cpp
// When signal is detected:
1. Calculate score (0.0-1.0)
2. Log signal to CSV
3. Record in PerformanceTracker

4. IF InpMLLiteEnabled == true:
   a. IF score < InpMLScoreThreshold:
      → FILTER signal (skip trade)
   b. ELSE:
      → Continue to execution
      
5. IF InpMLRiskScaling == true:
   a. IF score >= 0.80:
      → Multiply lot size by InpMLHighScoreMultiplier
   b. ELSE IF score >= 0.65:
      → Multiply lot size by InpMLMediumScoreMultiplier
   
6. Execute trade with (potentially scaled) lot size
```

---

## Tuning Guide

### Finding Your Optimal Threshold

**Method 1: Analyze Historical Data**

1. Run EA for 2-4 weeks with filtering OFF
2. Analyze CSV file: `signals_YYYY-MM.csv`
3. Group signals by score ranges
4. Calculate win rate for each range
5. Find threshold where win rate is acceptable

**Method 2: Progressive Testing**

Start high, work down:
1. **Week 1**: Threshold 0.70 (very selective)
2. **Week 2**: Threshold 0.65 (balanced)
3. **Week 3**: Threshold 0.60 (moderate)
4. Compare weekly performance

**Method 3: Dashboard Observation**

1. Enable ML-Lite with threshold 0.60
2. Check 6-hour dashboards
3. Look at High vs Medium tier win rates
4. Adjust threshold based on results

### Threshold Adjustment Rules

**Increase threshold if**:
- Win rate is too low
- Too many losing trades
- Drawdown is high
- Medium tier win rate < 55%

**Decrease threshold if**:
- Not enough trading opportunities
- Missing profitable signals
- Too few trades per week
- High tier is performing well

### Risk Scaling Guidelines

**Conservative** (Safe):
```
InpMLRiskScaling = true
InpMLHighScoreMultiplier = 1.2
InpMLMediumScoreMultiplier = 1.1
```

**Balanced** (Default):
```
InpMLRiskScaling = true
InpMLHighScoreMultiplier = 1.5
InpMLMediumScoreMultiplier = 1.2
```

**Aggressive** (Risky):
```
InpMLRiskScaling = true
InpMLHighScoreMultiplier = 2.0
InpMLMediumScoreMultiplier = 1.5
```

⚠️ **Warning**: Only enable risk scaling after confirming:
- Filtering improves win rate
- High tier consistently outperforms
- You're comfortable with larger positions

---

## Performance Dashboards

### Dashboard Schedule

**Automatic prints**:
- Every 6 hours (during trading)
- On EA shutdown (final summary)

**Manual trigger**: Restart EA to see immediate dashboard

### Dashboard Sections

#### 1. Score Tier Analysis

Shows performance by tier:
```
HIGH TIER (>= 0.70):
  Signals: 15 (12 taken, 3 skipped)
  Win Rate: 75.0% (9W/3L)
  Profit Factor: 2.85
  Expectancy: +30.1 pips/trade
```

**What to look for**:
- ✅ High tier win rate > 65%
- ✅ High tier expectancy > 0
- ✅ High tier PF > 1.5

#### 2. Overall Performance

Summary of all trades:
```
--- OVERALL PERFORMANCE ---
  Total Signals: 80
  Trades Taken: 37 (46.3%)
  Win Rate: 64.9% (24W/13L)
  Max Drawdown: -95.3 pips
```

**What to look for**:
- Trade reduction: 30-60% is normal
- Win rate improvement vs baseline
- Lower drawdown vs baseline

#### 3. Calibration Check

Verifies scoring accuracy:
```
--- CALIBRATION CHECK ---
  Score Prediction Accuracy: 85.2%
  High scores win more: YES ✅
  System is well-calibrated
```

**Green flags** (✅): High scores win more  
**Red flags** (⚠️): Scores not predictive → need retuning

---

## Best Practices

### ✅ Do's

1. **Start with baseline** - Run without filtering for 1 week
2. **Enable filtering gradually** - Don't rush into aggressive thresholds
3. **Monitor dashboards** - Check every 6 hours for trends
4. **Keep data collection ON** - Always log signals
5. **Document changes** - Note when you change parameters
6. **Compare periods** - Week-over-week analysis
7. **Test on demo first** - Validate before going live

### ❌ Don'ts

1. **Don't disable data collection** - You'll lose valuable insights
2. **Don't change multiple parameters at once** - Can't isolate what worked
3. **Don't set threshold too high initially** - Start moderate (0.60)
4. **Don't enable risk scaling immediately** - Confirm filtering works first
5. **Don't ignore calibration warnings** - If not calibrated, investigate
6. **Don't compare different market conditions** - Trending vs ranging
7. **Don't overtune** - Avoid optimizing for past performance only

### Configuration Recipes

**Recipe 1: Conservative Trader**
```
InpMLLiteEnabled = true
InpMLScoreThreshold = 0.70        // High quality only
InpMLRiskScaling = false          // Standard risk
```
**Result**: Fewest trades, highest quality

**Recipe 2: Balanced Trader** (Recommended)
```
InpMLLiteEnabled = true
InpMLScoreThreshold = 0.60        // Moderate filtering
InpMLRiskScaling = true
InpMLHighScoreMultiplier = 1.5
InpMLMediumScoreMultiplier = 1.2
```
**Result**: Good mix of quality and quantity

**Recipe 3: Aggressive Trader**
```
InpMLLiteEnabled = true
InpMLScoreThreshold = 0.50        // Light filtering
InpMLRiskScaling = true
InpMLHighScoreMultiplier = 2.0
InpMLMediumScoreMultiplier = 1.5
```
**Result**: More trades, scaled risk

---

## Troubleshooting

### Issue: No Signals Being Generated

**Check**:
1. Is EA running on a chart?
2. Are trading conditions met?
3. Check Experts log for "SIGNAL DETECTED"

**Solution**: This is normal if market conditions don't meet EA criteria

### Issue: All Signals Being Filtered

**Symptoms**: Dashboard shows all signals skipped

**Possible causes**:
- Threshold too high (try lowering to 0.55)
- Market conditions unusual
- Scoring system misaligned

**Solution**:
1. Check current threshold setting
2. Lower threshold by 0.05
3. Review recent signal scores in CSV

### Issue: Dashboard Not Printing

**Check**:
1. Is `InpMLLiteEnabled = true`?
2. Has 6 hours passed since last print?
3. Check Experts log

**Solution**: Restart EA to trigger immediate dashboard

### Issue: CSV File Not Created

**Check**:
1. Is `InpMLDataCollection = true`?
2. Check `MQL5/Files/ML_Data/` directory
3. Look for error messages in log

**Solution**: EA will create directory automatically on first signal

### Issue: Performance Not Improving

**Possible causes**:
- Threshold too low
- Not enough data yet (< 30 trades)
- Market regime change
- Baseline was already optimized

**Solution**:
1. Increase threshold to 0.65 or 0.70
2. Run for longer (2+ weeks)
3. Check calibration score
4. Compare baseline vs filtered metrics

---

## FAQ

**Q: How long should I run baseline before enabling filtering?**  
A: Minimum 1 week, ideally 2-4 weeks for statistical significance.

**Q: Can I use ML-Lite on multiple pairs?**  
A: Yes! Each EA instance tracks its own performance independently.

**Q: Will ML-Lite work on all timeframes?**  
A: Yes, scoring adapts to the timeframe. M15 is recommended for best results.

**Q: How many signals will be filtered?**  
A: Typically 30-60% at threshold 0.60, varies by market conditions.

**Q: Does filtering guarantee better performance?**  
A: No guarantees, but statistically improves win rate by filtering low-quality signals.

**Q: Can I disable ML-Lite anytime?**  
A: Yes, set `InpMLLiteEnabled = false` to revert to normal EA behavior.

**Q: What happens to filtered signals?**  
A: They're logged in CSV and PerformanceTracker but not executed.

**Q: How do I analyze CSV data?**  
A: Use Excel, Python pandas, or the included analysis tools (see Analysis Tools guide).

**Q: Should I use risk scaling?**  
A: Only after confirming filtering improves your results (after 2+ weeks).

**Q: What if calibration shows "NO"?**  
A: The scoring may need adjustment - collect more data and review tier performance.

---

## Next Steps

1. ✅ Enable data collection
2. ⏳ Run baseline for 1-2 weeks
3. 📊 Review dashboards and CSV
4. 🎯 Enable ML-Lite filtering
5. 📈 Compare performance
6. ⚙️ Optimize threshold
7. 🚀 Enable risk scaling (optional)

**Need Help?** Check the Technical Documentation for advanced topics.

---

**Version History**:
- v1.0 (2026-01-07): Initial release
