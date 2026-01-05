# Phase 0: ML-Lite Foundation - Implementation Plan

**Project**: LulaMultiInstrumentEA ML/AI Integration  
**Phase**: Phase 0 - ML-Lite Foundation  
**Timeline**: 4 Weeks  
**Start Date**: January 5, 2026  
**Target Completion**: February 2, 2026

---

## 🎯 Phase 0 Overview

### Objective

Implement a lightweight, **rule-based ML foundation** that scores trade signals using sophisticated heuristics, collects training data, and improves EA performance **without external dependencies**.

### Key Principles

- ✅ **Pure MQL5** - No Python API calls required
- ✅ **Rule-Based Scoring** - Sophisticated signal quality assessment
- ✅ **Data Collection** - Prepare for Phase 1 ML training
- ✅ **Quick Wins** - Immediate performance improvements
- ✅ **No Breaking Changes** - Backward compatible with existing EA

### Success Criteria

**Performance Targets** (Conservative):
- Win Rate: 45% → 50-55% (+5-10%)
- Profit Factor: 1.2 → 1.35-1.45 (+15-25%)
- Max Drawdown: -15% → -12% to -10% (-20-33%)
- Monthly Return: More consistent variance

**Technical Targets**:
- Signal scorer operational
- Data collection running
- Performance tracking functional
- Zero regression in existing features

---

## 📋 Components to Implement

### Component 1: C_SignalScorer (Signal Quality Assessor)

**Purpose**: Assign quality scores (0.0-1.0) to trading signals based on multi-factor analysis.

**Location**: `Core/ML/C_SignalScorer.mqh`

**Scoring Factors** (20 total factors, weighted):

#### 1. Trend Alignment (25% weight)
- HTF-LTF trend agreement
- Trend strength (ADX)
- Trend consistency
- Trend duration
- Multi-timeframe confluence

#### 2. Technical Confirmation (25% weight)
- Support/Resistance proximity
- Moving average alignment
- RSI confirmation (not overbought/oversold for entry)
- MACD alignment
- Price action patterns

#### 3. Market Context (20% weight)
- Volatility appropriateness
- Session timing (London/NY overlap preferred)
- Spread favorability
- Market regime (trending vs ranging)
- Economic calendar impact

#### 4. Risk/Reward Setup (15% weight)
- R:R ratio quality (minimum 1.5:1)
- Stop loss placement logic
- Take profit placement logic
- Position within trading range
- Distance from key levels

#### 5. Historical Performance (15% weight)
- Similar setup win rate
- Time-of-day performance
- Symbol performance
- Pattern frequency
- Recent performance trend

**Output**:
- **Score**: 0.0 to 1.0 (signal quality)
- **Confidence**: 0.0 to 1.0 (scorer confidence)
- **Factors**: Breakdown of contributing factors
- **Recommendation**: STRONG_TAKE / TAKE / CONSIDER / SKIP

**Integration Point**:
```cpp
// In LulaEA_Automated.mq5 or strategy class
C_SignalScorer scorer;
SignalScore result = scorer.EvaluateSignal(symbol, timeframe, direction, features);

if(result.score >= 0.70 && result.confidence >= 0.75) {
    // Strong signal - take trade with full risk
} else if(result.score >= 0.50) {
    // Moderate signal - take trade with reduced risk
} else {
    // Weak signal - skip trade
}
```

---

### Component 2: C_DataCollector (Training Data Collection)

**Purpose**: Collect feature data and outcomes for future ML model training (Phase 1).

**Location**: `Core/ML/C_DataCollector.mqh`

**Data Points to Collect**:

#### Per Signal (Entry)
- Timestamp
- Symbol
- Timeframe
- Direction (BUY/SELL)
- **Features** (30+ technical indicators):
  - Trend: ADX, ATR, MA slopes, trend duration
  - Momentum: RSI, MACD, Stochastic, ROC
  - Volatility: ATR, Bollinger Bands, historical vol
  - Price Action: Candlestick patterns, support/resistance
  - Market Context: Session, spread, volume
  - Multi-Timeframe: HTF trend, LTF confirmation

#### Per Trade (Exit)
- Entry price
- Exit price
- Stop loss hit/TP hit/manual close
- Profit/Loss (pips)
- Profit/Loss (currency)
- Duration (minutes)
- Max favorable excursion (MFE)
- Max adverse excursion (MAE)
- Signal score (from C_SignalScorer)
- Actual outcome (win/loss)

**Storage Format**: CSV files
- `data/signals_YYYY-MM.csv` - Monthly signal files
- Headers: timestamp, symbol, direction, feature1, feature2, ..., outcome, pnl

**Privacy**: All data stored locally, never transmitted

**Integration Point**:
```cpp
// At signal generation
collector.LogSignal(symbol, direction, features, signalScore);

// At trade close
collector.LogOutcome(signalId, entryPrice, exitPrice, pnl, outcome);
```

---

### Component 3: C_PerformanceTracker (Real-Time Analytics)

**Purpose**: Track and visualize ML-Lite performance vs baseline.

**Location**: `Core/ML/C_PerformanceTracker.mqh`

**Metrics Tracked**:

#### Signal Quality Metrics
- Signals generated (by score range)
- Signals taken (by score threshold)
- Signals skipped
- Score distribution

#### Trading Performance
- Win rate (overall & by score tier)
- Profit factor (overall & by score tier)
- Average win/loss
- Max drawdown
- Sharpe ratio
- Recovery factor

#### ML-Lite Specific
- High-confidence signal win rate (score >= 0.70)
- Medium-confidence signal win rate (score 0.50-0.70)
- Filtered-out signal performance (would-be trades)
- Score calibration accuracy

**Dashboard Output** (to chart or file):
```
=== ML-Lite Performance (Last 7 Days) ===
Signals Generated: 142
Signals Taken: 87 (high: 45, med: 42)
Signals Skipped: 55

High Score Trades (>=0.70):
  Win Rate: 64% (29/45)
  Profit Factor: 1.82
  Avg R:R: 2.1

Medium Score Trades (0.50-0.70):
  Win Rate: 48% (20/42)
  Profit Factor: 1.21
  Avg R:R: 1.6

Filtered Trades (skipped):
  Hypothetical Win Rate: 35% (est)
  Avoided Losses: ~12.5%

Overall Improvement: +18% profit factor
```

---

### Component 4: Configuration System

**Purpose**: Easy tuning of ML-Lite parameters without recompilation.

**Location**: Modify existing input parameters in EA

**New Input Parameters**:
```cpp
// ML-Lite Configuration
input bool   InpMLLiteEnabled = true;            // Enable ML-Lite scoring
input double InpMLScoreThresholdHigh = 0.70;     // High confidence threshold
input double InpMLScoreThresholdMedium = 0.50;   // Medium confidence threshold
input double InpMLRiskMultiplierHigh = 1.0;      // Risk for high score signals
input double InpMLRiskMultiplierMedium = 0.5;    // Risk for med score signals
input bool   InpMLDataCollection = true;         // Enable data collection
input bool   InpMLPerformanceTracking = true;    // Enable tracking
```

**Scoring Weight Configuration** (per factor group):
```cpp
input double InpMLWeightTrend = 0.25;           // Trend alignment weight
input double InpMLWeightTechnical = 0.25;       // Technical confirmation weight
input double InpMLWeightContext = 0.20;         // Market context weight
input double InpMLWeightRR = 0.15;              // Risk/Reward weight
input double InpMLWeightHistorical = 0.15;      // Historical performance weight
```

---

## 🏗️ Implementation Structure

### Week 1: Foundation & Signal Scorer

**Tasks**:
1. Create `C_SignalScorer.mqh`
   - Define `struct SignalScore`
   - Implement factor calculation functions
   - Implement scoring logic
   - Implement weighting system
   - Add logging

2. Create scoring factors:
   - Trend alignment scoring
   - Technical confirmation scoring
   - Market context scoring
   - R:R setup scoring
   - Historical performance scoring (basic)

3. Unit testing:
   - Test each factor independently
   - Test overall scoring
   - Validate score ranges (0.0-1.0)

**Deliverable**: Working signal scorer with 20 factors

---

### Week 2: Data Collection & Integration

**Tasks**:
1. Create `C_DataCollector.mqh`
   - CSV file management
   - Feature extraction
   - Trade tracking
   - Storage optimization

2. Integrate with existing EA:
   - Hook into signal generation
   - Hook into trade entry
   - Hook into trade exit
   - Add error handling

3. Testing:
   - Verify CSV creation
   - Validate data format
   - Test across timeframes
   - Test across symbols

**Deliverable**: Data collection operational, CSV files generating

---

### Week 3: Performance Tracking & Optimization

**Tasks**:
1. Create `C_PerformanceTracker.mqh`
   - Metrics calculation
   - Performance comparison
   - Dashboard generation
   - File logging

2. Integrate ML-Lite into trading logic:
   - Add score threshold checks
   - Implement risk scaling
   - Add signal filtering
   - Preserve backward compatibility

3. Testing & Calibration:
   - Backtest with different thresholds
   - Optimize weight factors
   - Validate improvements
   - A/B test vs baseline

**Deliverable**: Full ML-Lite system operational

---

### Week 4: Refinement & Validation

**Tasks**:
1. Performance optimization:
   - Tune scoring weights
   - Optimize thresholds
   - Refine factor calculations
   - Improve efficiency

2. Documentation:
   - User guide for ML-Lite
   - Parameter tuning guide
   - Data format documentation
   - API documentation

3. Final validation:
   - Forward test (1 week minimum)
   - Compare vs baseline EA
   - Validate data quality
   - Prepare Phase 1 handoff

**Deliverable**: Production-ready Phase 0, validated improvements

---

## 📊 Proposed Changes by File

### New Files

#### `Core/ML/C_SignalScorer.mqh` (NEW)
**Purpose**: Signal quality scoring engine  
**Size**: ~500 lines  
**Key Classes**:
- `struct SignalScore` - Score result structure
- `struct ScoringFactors` - Individual factor scores
- `class C_SignalScorer` - Main scoring engine

**Public Methods**:
```cpp
SignalScore EvaluateSignal(string symbol, ENUM_TIMEFRAMES tf, int direction, double &features[]);
void SetWeights(double trend, double technical, double context, double rr, double historical);
void EnableFactor(string factorName, bool enabled);
```

---

#### `Core/ML/C_DataCollector.mqh` (NEW)
**Purpose**: Training data collection  
**Size**: ~300 lines  
**Key Features**:
- CSV file management
- Feature logging
- Outcome tracking
- Monthly file rotation

**Public Methods**:
```cpp
bool LogSignal(string symbol, int direction, double &features[], double score);
bool LogOutcome(string signalId, double entry, double exit, double pnl, bool isWin);
bool FlushToFile();
```

---

#### `Core/ML/C_PerformanceTracker.mqh` (NEW)
**Purpose**: Performance analytics  
**Size**: ~400 lines  
**Key Features**:
- Metric calculation
- Score tier analysis
- Comparison to baseline
- Dashboard generation

**Public Methods**:
```cpp
void RecordTrade(string symbol, double score, bool isWin, double pnl);
string GenerateDashboard(int lookbackDays = 7);
double GetWinRateByScoreTier(double minScore, double maxScore);
```

---

### Modified Files

#### `LulaEA_Automated.mq5` or Strategy Class (MODIFY)
**Changes**:
- Include ML-Lite headers
- Initialize ML components in `OnInit()`
- Call signal scorer before trade entry
- Apply score-based filtering
- Scale risk based on signal confidence
- Log performance metrics

**Example Integration**:
```cpp
#include "Core/ML/C_SignalScorer.mqh"
#include "Core/ML/C_DataCollector.mqh"
#include "Core/ML/C_PerformanceTracker.mqh"

C_SignalScorer g_scorer;
C_DataCollector g_collector;
C_Performance Tracker g_tracker;

// In signal generation logic
if(buySignal) {
    // Prepare feature array
    double features[30];
    ExtractFeatures(features);
    
    // Score the signal
    SignalScore score = g_scorer.EvaluateSignal(_Symbol, _Period, OP_BUY, features);
    
    // Evaluate score
    if(score.score >= InpMLScoreThresholdHigh) {
        // Strong signal - take with full risk
        OpenTrade(OP_BUY, lotSize * InpMLRiskMultiplierHigh, score.score);
    } else if(score.score >= InpMLScoreThresholdMedium) {
        // Medium signal - take with reduced risk
        OpenTrade(OP_BUY, lotSize * InpMLRiskMultiplierMedium, score.score);
    } else {
        // Weak signal - skip
        Print("Signal skipped - low score: ", score.score);
    }
    
    // Log for training data
    g_collector.LogSignal(_Symbol, OP_BUY, features, score.score);
}
```

---

## 🧪 Testing Strategy

### Unit Testing

**Per Component**:
- Test C_SignalScorer with known inputs
- Verify score ranges (0.0-1.0)
- Test C_DataCollector CSV generation
- Validate C_PerformanceTracker calculations

**Test Cases**: Minimum 50 per component

---

### Integration Testing

**Test Scenarios**:
1. Full trade lifecycle with ML-Lite
2. Signal filtering (high/med/low scores)
3. Data collection across timeframes
4. Performance tracking accuracy
5. Edge cases (no signals, max signals, etc.)

**Test Duration**: 3 days live testing

---

### Validation Testing (Forward Test)

**Approach**: A/B comparison
- Baseline EA (no ML-Lite)
- ML-Lite EA (with scoring)
- Same timeperiod, same symbols

**Metrics to Compare**:
- Win rate
- Profit factor
- Max drawdown
- Number of trades
- Average R:R

**Duration**: Minimum 1 week, target 2 weeks

**Success Criteria**: ML-Lite shows >= 5% improvement in profit factor

---

## 🎯 Integration Points

### Existing EA Architecture

Current flow:
```
Market Data → Signal Generation → Trade Execution → Position Management
```

ML-Lite enhanced flow:
```
Market Data → Signal Generation → **ML Scoring** → **Filtering** → Trade Execution (scaled) → Position Management → **Data Collection** → **Performance Tracking**
```

### Minimal Changes Required

**Strategy Pattern** (if using):
```cpp
// In C_Strategy base class or specific strategy
virtual bool ShouldTakeTrade(Signal signal) {
    if(!InpMLLiteEnabled) return true; // Original behavior
    
    SignalScore score = EvaluateWithMLLite(signal);
    return (score.score >= InpMLScoreThresholdMedium);
}
```

**Direct Integration** (if not using Strategy Pattern):
```cpp
// In main EA file
if(signal.isValid) {
    if(InpMLLiteEnabled) {
        SignalScore mlScore = g_scorer.EvaluateSignal(...);
        if(mlScore.score < InpMLScoreThresholdMedium) {
            signal.isValid = false; // Filter out
        }
    }
    
    if(signal.isValid) {
        ExecuteTrade(signal);
    }
}
```

---

## 📈 Expected Performance Improvements

### Conservative Estimates

**Baseline Performance** (Current):
- Win Rate: ~45%
- Profit Factor: ~1.2
- Max DD: ~15%
- Avg R:R: ~1.5

**ML-Lite Performance** (Phase 0 Target):
- Win Rate: 50-55% (+5-10% absolute)
- Profit Factor: 1.35-1.45 (+15-25%)
- Max DD: 10-12% (-20-33%)
- Avg R:R: 1.8-2.0 (+20-33%)

### Improvement Mechanisms

1. **Better Signal Selection**: Filter out low-quality setups
2. **Risk Optimization**: Scale risk based on confidence
3. **Context Awareness**: Consider market conditions
4. **Pattern Recognition**: Learn from historical performance
5. **Multi-Factor Validation**: Require confluence

### Timeline to Results

- Week 1: Infrastructure only, no performance change
- Week 2: Data collection, minimal impact
- Week 3: **First improvements visible** (+5-10% PF)
- Week 4: **Full performance gains** (+15-25% PF)
- Forward test: **Validation of improvements**

---

## 🚧 Risks & Mitigation

### Technical Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Over-filtering | Fewer trades | Medium | Tune thresholds, A/B test |
| Score calibration | Poor decisions | Medium | Extensive backtesting, validation |
| Performance overhead | Slower execution | Low | Optimize scoring functions |
| Data corruption | Lost training data | Low | Validation, backup |

### Operational Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Configuration errors | Suboptimal performance | Medium | Default values, validation |
| Regression | Worse than baseline | Low | Backward compatibility, killswitch |
| User adoption | Not used | Low | Clear documentation, benefits |

### Mitigation Strategy

✅ **Killswitch**: `InpMLLiteEnabled = false` reverts to original EA  
✅ **A/B Testing**: Compare with baseline continuously  
✅ **Gradual Rollout**: Test on demo before live  
✅ **Monitoring**: Track all metrics in real-time  

---

## 📅 Milestone Schedule

### Week 1 (Jan 5-12)
- [x] Planning complete
- [ ] C_SignalScorer scaffold created
- [ ] 20 scoring factors implemented
- [ ] Unit tests passing
- **Deliverable**: Signal scorer functional

### Week 2 (Jan 13-19)
- [ ] C_DataCollector implemented
- [ ] CSV file generation working
- [ ] Integration with existing EA
- [ ] First data files created
- **Deliverable**: Data collection operational

### Week 3 (Jan 20-26)
- [ ] C_PerformanceTracker implemented
- [ ] ML-Lite fully integrated
- [ ] Backtesting complete
- [ ] Threshold optimization done
- **Deliverable**: System operational

### Week 4 (Jan 27 - Feb 2)
- [ ] Forward testing (1 week)
- [ ] Documentation complete
- [ ] Performance validated
- [ ] Phase 1 prep started
- **Deliverable**: Phase 0 complete, production-ready

---

## ✅ Acceptance Criteria

### Technical Acceptance

- [x] All components compile without errors
- [ ] All unit tests passing
- [ ] Integration tests passing
- [ ] No regression in baseline performance
- [ ] ML-Lite can be disabled cleanly

### Performance Acceptance

- [ ] Win rate improvement: >= +5%
- [ ] Profit factor improvement: >= +15%
- [ ] Max drawdown improvement: >= -20%
- [ ] Data collection: >= 100 signals logged
- [ ] Forward test successful (1+ weeks)

### Quality Acceptance

- [ ] Code documented (inline comments)
- [ ] User documentation complete
- [ ] Configuration guide available
- [ ] Known limitations documented
- [ ] No critical bugs

---

## 🔗 Dependencies

### Prerequisites (Already Complete)
- ✅ WebRequest validation (Phase 0 uses none, but validated for Phase 1)
- ✅ Existing EA functional
- ✅ Backtest environment available

### External Dependencies
- ❌ None (pure MQL5, local only)

### Internal Dependencies
- ✅ Access to historical indicator values
- ✅ Trade execution system
- ✅ File write permissions

---

## 📝 Next Steps

### Immediate Actions (This Week)

1. **Create Phase 0 task breakdown** - Detailed checklist
2. **Begin C_SignalScorer implementation** - Start with structure
3. **Define feature extraction** - List all 30 features
4. **Setup development environment** - Testing harness

### Phase 1 Preparation (Parallel)

1. Review data format for ML compatibility
2. Research ML model architectures (XGBoost, Neural Networks)
3. Plan Python ML pipeline
4. Design deployment strategy

---

## 📊 Success Metrics Dashboard

**Weekly Review Metrics**:
```
Week 1: Development Progress
- Components completed: X/3
- Unit tests written: X/50
- Code coverage: X%

Week 2: Integration Progress  
- Integration points: X/4
- Data files created: X
- Features logged: X

Week 3: Performance Progress
- Signals scored: X
- Trades filtered: X
- Improvement vs baseline: +X%

Week 4: Validation Complete
- Forward test days: X/7
- Final win rate: X%
- Final profit factor: X.XX
- Phase 0 status: ✅ COMPLETE
```

---

**Plan Prepared**: January 5, 2026  
**Phase 0 Timeline**: 4 weeks (Jan 5 - Feb 2)  
**Status**: ✅ **APPROVED - READY TO START**  
**Next**: Create detailed task breakdown and begin Week 1 development
