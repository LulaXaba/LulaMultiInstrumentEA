# ML-Lite Parameter Tuning Guide

**Version**: 1.0  
**Last Updated**: January 7, 2026

---

## Quick Reference

### Recommended Starting Points

**Conservative Setup**:
```
Threshold: 0.70
Risk Scaling: OFF
Expected: Fewest trades, highest quality
```

**Balanced Setup** (Recommended):
```
Threshold: 0.60
Risk Scaling: ON (1.5x / 1.2x)
Expected: Good balance of quality/quantity
```

**Aggressive Setup**:
```
Threshold: 0.50
Risk Scaling: ON (2.0x / 1.5x)
Expected: More trades, scaled risk
```

---

## Threshold Selection Guide

### Finding Your Threshold

**Step 1: Collect Baseline Data**
- Run EA for 2-4 weeks without filtering
- Analyze `signals_YYYY-MM.csv`
- Calculate win rate by score range

**Step 2: Score Distribution Analysis**

Group signals by score:
- 0.00-0.50: Count, Win Rate
- 0.50-0.60: Count, Win Rate
- 0.60-0.70: Count, Win Rate
- 0.70-0.80: Count, Win Rate
- 0.80-1.00: Count, Win Rate

**Step 3: Select Threshold**

Choose score where:
- Win rate >= 60%
- Enough signals (>10 per week)
- Profit factor > 1.5

### Threshold Tuning Matrix

| Threshold | Trade Reduction | Expected WR | Use When |
|-----------|----------------|-------------|----------|
| 0.50 | ~20% | 55-60% | Want more signals |
| 0.55 | ~30% | 58-63% | Light filtering |
| 0.60 | ~40% | 62-67% | **Balanced** |
| 0.65 | ~50% | 65-70% | Conservative |
| 0.70 | ~60% | 68-73% | Very selective |
| 0.75 | ~70% | 70-75% | Rare high-quality only |

---

## Risk Scaling Optimization

### When to Enable

✅ **Enable risk scaling when**:
- Filtering has proven effective (2+ weeks)
- High tier consistently outperforms
- You understand the risks
-Capital allows for scaled positions

❌ **Don't enable if**:
- Still testing filtering
- High tier win rate < 65%
- Small account (<$1,000)
- Risk-averse trader

### Multiplier Selection

**Conservative** (Safest):
```
High Score (0.80+): 1.2x
Medium Score (0.65-0.79): 1.1x
```
**Impact**: Minimal increase, safer testing

**Balanced** (Recommended):
```
High Score (0.80+): 1.5x
Medium Score (0.65-0.79): 1.2x
```
**Impact**: Moderate increase, good balance

**Aggressive** (Higher Risk):
```
High Score (0.80+): 2.0x
Medium Score (0.65-0.79): 1.5x
```
**Impact**: Significant increase, higher risk

### Risk Scaling Examples

**Baseline lot**: 0.10  
**With 1.5x multiplier**: 0.15  
**With 2.0x multiplier**: 0.20

**Impact on drawdown**:
- 1.5x: Up to 50% larger DD
- 2.0x: Up to 100% larger DD

⚠️ **Always test on demo first!**

---

## Optimization Workflow

### Week-by-Week Approach

**Week 1: Baseline**
```
InpMLLiteEnabled = false
```
Goal: Establish normal performance

**Week 2: Light Filtering**
```
InpMLLiteEnabled = true
InpMLScoreThreshold = 0.55
InpMLRiskScaling = false
```
Goal: Test filtering with minimal impact

**Week 3: Moderate Filtering**
```
InpMLScoreThreshold = 0.60
```
Goal: Find optimal balance

**Week 4: Optimization**
```
InpMLScoreThreshold = [adjusted based on results]
InpMLRiskScaling = true (if week 3 successful)
```
Goal: Fine-tune and enable scaling

### A/B Testing Method

Run 2 instances simultaneously:

**Instance A** (Control):
```
Threshold: 0.60
Risk Scaling: OFF
```

**Instance B** (Test):
```
Threshold: 0.65 (or 0.55)
Risk Scaling: ON
```

Compare after 2 weeks.

---

## Performance Targets

### Success Metrics

**Good Results** (Worth keeping):
- Win rate improvement: +5% vs baseline
- Profit factor improvement: +15% vs baseline
- Max drawdown reduction: -20% vs baseline
- Trade reduction: 30-50%

**Excellent Results** (Optimal):
- Win rate improvement: +10% vs baseline
- Profit factor improvement: +25% vs baseline
- Max drawdown reduction: -30% vs baseline
- Calibration score: >80%

**Poor Results** (Needs adjustment):
- Win rate same or worse
- Profit factor decreased
- Trade reduction: >70%
- Calibration score: <60%

### What to Do Based on Results

**If win rate improved but too few trades**:
→ Lower threshold by 0.05

**If win rate same/worse**:
→ Increase threshold by 0.05

**If high tier WR < medium tier WR**:
→ System not calibrated, collect more data

**If excellent results**:
→ Consider enabling risk scaling

---

## Advanced Tuning

### Dynamic Threshold

Adjust threshold based on market conditions:

```cpp
// Example: Tighter during high volatility
double threshold = baseThreshold;
if(currentVolatility > averageVolatility * 1.5)
   threshold += 0.05; // More selective

if(score.score >= threshold)
   // Execute
```

### Session-Based Tuning

Different thresholds for different sessions:

```cpp
int hour = TimeHour(TimeCurrent());

double threshold;
if(hour >= 8 && hour <= 16)      // London/NY
   threshold = 0.55;  // More liquid = lower threshold
else
   threshold = 0.65;  // Less liquid = higher threshold
```

### Pair-Specific Tuning

Different thresholds per pair:

```cpp
double threshold;
if(Symbol() == "EURUSD")
   threshold = 0.60;
else if(Symbol() == "GBPUSD")
   threshold = 0.65;  // More volatile = stricter
```

---

## Common Scenarios

### Scenario 1: Not Enough Signals

**Problem**: Only 2-3 trades per week  
**Solution**: Lower threshold
- Try 0.55 or 0.50
- Check if baseline had more signals
- Consider time of day filtering

### Scenario 2: Win Rate Not Improving

**Problem**: Same WR as baseline  
**Solution**: Increase threshold
- Try 0.65 or 0.70
- Check calibration score
- Review scoring factor weights

### Scenario 3: High Scores Losing

**Problem**: High tier WR < 60%  
**Solution**: System miscalibration
- Collect more data (4+ weeks)
- Review factor implementation
- Check market regime change

### Scenario 4: Excessive Filtering

**Problem**: >70% signals filtered  
**Solution**: Threshold too high
- Lower to 0.55 or 0.50
- Review score distribution
- Check if scoring too harsh

---

## Monitoring Checklist

### Daily
- [ ] Check Experts log for filtered signals
- [ ] Verify CSV file is updating
- [ ] Monitor trade execution

### Weekly
- [ ] Review 6-hour dashboards
- [ ] Check win rate by tier
- [ ] Analyze signal count
- [ ] Compare to previous week

### Monthly
- [ ] Full performance analysis
- [ ] Threshold optimization review
- [ ] Risk scaling assessment
- [ ] Parameter adjustment if needed

---

## Best Practices

1. **Change one parameter at a time**
2. **Test for minimum 2 weeks** before adjusting
3. **Document all changes** with dates
4. **Keep baseline instance** running for comparison
5. **Use demo account** for aggressive tuning
6. **Monitor calibration** regularly
7. **Don't overtune** - avoid curve fitting

---

## Troubleshooting

**Q: Threshold 0.60 filters everything**  
A: Score distribution is too low. Lower to 0.50 or check scoring logic.

**Q: Risk scaling causing large losses**  
A: Multipliers too high or tier not performing well. Disable or reduce multipliers.

**Q: Calibration shows "NO"**  
A: Not enough data or scoring issue. Collect 50+ signals and recheck.

**Q: Results worse than baseline**  
A: Either threshold is wrong OR baseline was already optimal. Try different threshold or disable.

---

**Version**: 1.0 (2026-01-07)
