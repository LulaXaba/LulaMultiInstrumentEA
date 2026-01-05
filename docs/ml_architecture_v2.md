# ML/AI Integration - System Architecture v2.0 (Revised)

**Revised**: January 2026  
**Status**: Feasibility-Reviewed & Optimized

This document provides a visual and technical overview of the revised ML/AI integration architecture for LulaMultiInstrumentEA.

---

## Overview: Phased Approach

> [!NOTE]
> **Key Change from v1.0**
> 
> The original plan attempted to implement full ML infrastructure immediately. The revised approach uses a **3-phase strategy** to reduce risk and deliver incremental value:
> 
> - **Phase 0**: ML-Lite (rule-based scoring) - Quick wins in 2-4 weeks
> - **Phase 1**: True ML via Python API - Full ML integration over 8 weeks
> - **Phase 2+**: Advanced features (SL/TP, regime, position sizing)

---

## System Architecture Diagram

![ML Architecture - Phased Approach](C:/Users/Admin/.gemini/antigravity/brain/8ff2c6f5-c967-4101-a0b9-6b0867779641/ml_architecture_revised_1767228271187.png)

### Phase 0: ML-Lite Foundation (Weeks 1-4)

**Purpose**: Implement rule-based multi-factor scoring before investing in full ML infrastructure

**Components**:

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **C_SignalScorer** | Pure MQL5 | Score signals 0.0-1.0 based on 5 factors |
| **Scoring Factors** | Rule-based logic | Trend alignment, volatility, pattern strength, S/R confluence, time |
| **Signal Filter** | Threshold check | Only execute if score ≥ 0.70 |
| **C_DataCollector** | MQL5 + CSV export | Collect training data for Phase 1 |

**Data Flow**:
```
Market Data → Existing EA Analysis → C_SignalScorer (5 factors) 
→ Signal Filter (score ≥ 0.70?) → Execute Trade
                                ↓ (log features + outcome)
                           C_DataCollector → CSV File
```

**Expected Impact**:
- ✅ 5-15% win rate improvement
- ✅ Baseline for ML comparison
- ✅ Data collection begins
- ✅ 2-4 week implementation

---

### Phase 1: True ML Integration (Weeks 5-12)

**Purpose**: Replace rule-based scoring with learned ML model

**Components**:

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Feature Extractor** | MQL5 | Convert market state to 80-dimensional feature vector |
| **ML Model** | XGBoost (Python) | Predict win probability 0.0-1.0 |
| **FastAPI Server** | Python + FastAPI | REST API serving model predictions |
| **C_MLClient** | MQL5 WebRequest | Call API, handle responses, fallback |
| **Fallback Logic** | C_SignalScorer | Use ML-Lite if API fails |

**Data Flow**:
```
Market Data → Feature Extraction (80 features) → Split
                                                   ↓
                                    ┌──────────────┴──────────────┐
                                    ↓                             ↓
                          FastAPI Server                   Fallback: ML-Lite
                          ML Model (XGBoost)              (if API fails)
                          Returns: score (0.0-1.0)         Returns: score
                                    ↓                             ↓
                                    └──────────────┬──────────────┘
                                                   ↓
                                         Decision Point (score ≥ 0.65?)
                                                   ↓
                                            Execute Trade
```

**API Architecture**:

```python
# FastAPI Server (runs locally or on VPS)
POST /predict/signal_quality
Request: {"features": [0.5, 0.3, ..., 80 values]}
Response: {"score": 0.78, "should_trade": true, "latency_ms": 15}

GET /health
Response: {"status": "healthy", "model_loaded": true}
```

**MQL5 Integration**:

```cpp
// In strategy class
double features[80];
ExtractFeatures(features);  // Get market state

// Call ML API
double score = m_mlClient.GetSignalScore(features, signal, analyzer);

// Automatic fallback if API fails
if(score < 0) {
   score = m_fallbackScorer.ScoreSignal(signal, analyzer);
}

// Filter signal
if(score < 0.65) return PATTERN_NONE;
```

**Expected Impact**:
- ✅ Additional 5-10% win rate improvement over ML-Lite
- ✅ Total 10-20% improvement vs baseline
- ✅ Learns patterns humans miss
- ✅ 8 week implementation

---

### Phase 2+: Future Enhancements (Month 7+)

**Advanced ML Models** (implemented sequentially after Phase 1 validation):

#### 1. SL/TP Optimizer

**Purpose**: Predict optimal stop-loss and take-profit levels for each trade

**Technology**: Regression model (Random Forest or XGBoost)

**Inputs**:
- Current market features (volatility, trend strength, support/resistance)
- Instrument characteristics
- Time of day, session

**Outputs**:
- `optimal_sl_pips`: Recommended stop-loss distance
- `optimal_tp_pips`: Recommended take-profit distance
- `expected_duration`: Expected trade holding time

**Integration**: Modify `C_RiskManager` to use ML predictions instead of fixed ratios

**Expected Impact**: +10-15% profit factor improvement

---

#### 2. Market Regime Classifier

**Purpose**: Identify current market regime to adapt strategy

**Technology**: Multi-class classifier (Random Forest, LSTM)

**Inputs**:
- Historical price data (last 50-100 bars)
- Volatility metrics (ATR, Bollinger Band width)
- Volume indicators
- Trend indicators

**Outputs** (one of 5 regimes):
- `TRENDING_BULL`: Strong uptrend
- `TRENDING_BEAR`: Strong downtrend
- `RANGING`: Consolidation, no clear direction
- `HIGH_VOLATILITY`: News-driven, unpredictable
- `BREAKOUT`: Potential regime change

**Integration**: Strategy selection and risk adjustment based on regime

**Actions by Regime**:
- **TRENDING**: Enable trend-following strategies, wider stops
- **RANGING**: Disable or reduce position sizes
- **HIGH_VOLATILITY**: Pause trading or use tighter stops
- **BREAKOUT**: Increase position sizes for high-confidence setups

**Expected Impact**: -20-30% drawdown reduction

---

#### 3. Dynamic Position Sizer

**Purpose**: Adjust position size based on signal confidence and portfolio state

**Technology**: Reinforcement Learning or Regression

**Inputs**:
- ML signal confidence score
- Current account drawdown
- Recent win/loss streak
- Market volatility
- Correlation with existing positions

**Output**:
- `risk_multiplier`: 0.5x to 2.0x (applied to base risk percentage)

**Logic**:
```
Base Risk: 1.5%
Signal Score: 0.85 (high confidence) → Multiplier: 1.5x → Risk: 2.25%
Signal Score: 0.67 (medium confidence) → Multiplier: 0.8x → Risk: 1.2%
In Drawdown (-8%) → Reduce multiplier by 30%
High Volatility → Reduce multiplier by 20%
```

**Expected Impact**: +15-25% Sharpe ratio improvement

---

## Implementation Timeline

![Implementation Timeline](C:/Users/Admin/.gemini/antigravity/brain/8ff2c6f5-c967-4101-a0b9-6b0867779641/ml_timeline_gantt_1767228293047.png)

### Phase Breakdown

| Phase | Duration | Key Milestones | Validation Gate |
|-------|----------|----------------|-----------------|
| **Phase 0** | Weeks 1-4 | ML-Lite implemented, data collection active | Win rate +5% vs baseline |
| **Phase 1** | Weeks 5-12 | ML model trained, API deployed, MQL5 integrated | Backtest: +10% win rate |
| **Phase 2** | Weeks 13-20 | Demo testing, performance monitoring | Demo within 20% of backtest |
| **Phase 3** | Weeks 21-28 | Live small capital, validation | Live meets conservative targets |

**Critical Milestones**:
- ✅ **Week 4**: Training data collected (500-1000 trades)
- ✅ **Week 12**: ML integrated and validated in backtests
- ✅ **Week 20**: Demo performance confirms backtest expectations
- ✅ **Week 28**: Production-ready, decision to scale up

**Future Phases** (not shown):
- **Phase 4** (Weeks 29-36): Dynamic SL/TP implementation
- **Phase 5** (Weeks 37-44): Market regime classification
- **Phase 6** (Ongoing): Continuous improvement and monitoring

---

## Performance Projections

![Performance Comparison](C:/Users/Admin/.gemini/antigravity/brain/8ff2c6f5-c967-4101-a0b9-6b0867779641/performance_comparison_chart_1767228323600.png)

### Performance Metrics Across Phases

| Metric | Current Baseline | Phase 0 (ML-Lite) | Phase 1+ (True ML) | Long-term (All Features) |
|--------|------------------|-------------------|-------------------|------------------------|
| **Win Rate** | 50% | 55% (+10%) | 60% (+20%) | 65-70% (+30-40%) |
| **Profit Factor** | 1.5 | 1.7 (+13%) | 2.0 (+33%) | 2.2-2.5 (+47-67%) |
| **Max Drawdown** | 15% | 13% (-13%) | 10% (-33%) | 8-9% (-40-47%) |
| **Monthly Return** | 5% | 7% (+40%) | 12% (+140%) | 15-20% (+200-300%) |
| **Sharpe Ratio** | 1.0 | 1.4 (+40%) | 1.8 (+80%) | 2.0-2.5 (+100-150%) |

### Incremental Value

**Phase 0 Contribution** (ML-Lite):
- Low-hanging fruit: filter obviously bad signals
- Quick implementation: 2-4 weeks
- Foundation for data collection
- Expected: 5-10% win rate boost

**Phase 1 Contribution** (True ML):
- Learned patterns beyond rules
- Adaptive to market changes
- Additional 5-10% win rate improvement
- Total: 10-20% above baseline

**Phase 2+ Contribution** (Advanced Features):
- Optimized exits (SL/TP)
- Regime awareness
- Smart position sizing
- Additional 5-15% improvement
- Total: 15-35% above baseline

---

## Technical Architecture Deep Dive

### Feature Engineering Pipeline

**Raw Market Data** → **Feature Extraction** → **Normalization** → **ML Model**

#### Feature Categories (80 total features)

**1. Technical Indicators** (25 features):
```
- RSI (M15, M30, H1): 3 features
- MACD (M15, M30, H1): 6 features (value + signal)
- ADX (M15, H1): 2 features
- ATR (H1, H4): 2 features
- Moving Averages: 6 features (MA20, MA50, MA200 slopes M15/H1)
- Bollinger Bands: 3 features (width, %B, position)
- Stochastic: 3 features
```

**2. Market Structure** (20 features):
```
- Trend direction (M15, M30, H1, H4): 4 features (encoded -1/0/1)
- Trend strength (M15, H1): 2 features (0-100)
- Distance to S/R levels: 4 features (nearest above/below, count nearby)
- Swing high/low distances: 4 features
- Price position in recent range: 2 features
- Candlestick body/wick ratios: 4 features
```

**3. Pattern Features** (10 features):
```
- Pattern type: 10 features (one-hot encoded)
- Pattern strength score: 1 feature
- Harmonic detected: 1 feature (boolean)
- In PRZ zone: 1 feature (boolean)
```

**4. Time Features** (5 features):
```
- Hour of day: 1 feature (0-23)
- Day of week: 1 feature (one-hot or 0-6)
- Trading session: 3 features (Asian/London/NY one-hot)
```

**5. Order Flow Features** (10 features):
```
- Win streak: 1 feature
- Loss streak: 1 feature
- Win rate last 20 trades: 1 feature
- Current drawdown %: 1 feature
- Trades today: 1 feature
- Last trade profit/loss: 1 feature
- Days since last trade: 1 feature
- Average profit per trade (rolling): 1 feature
```

**6. Instrument Features** (10 features):
```
- Current spread: 1 feature
- Average spread (24h): 1 feature
- Spread percentile: 1 feature
- ATR percentile: 1 feature
- Volatility regime: 1 feature (encoded)
- Correlation with EURUSD: 1 feature
- Correlation with DXY: 1 feature
- Instrument type: 3 features (Forex/Index/Commodity one-hot)
```

**Total**: 80 features

**Normalization Methods**:
- **Continuous features**: StandardScaler (z-score normalization)
- **Categorical features**: One-hot encoding or ordinal encoding
- **Boolean features**: 0/1 binary

---

### API Communication Protocol

#### Request Format

```json
POST /predict/signal_quality HTTP/1.1
Host: localhost:8000
Content-Type: application/json

{
  "features": [
    0.523,   // RSI_M15 (normalized)
    0.345,   // RSI_M30
    0.678,   // RSI_H1
    // ... 77 more features
  ]
}
```

#### Response Format

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "score": 0.782,           // Win probability (0.0-1.0)
  "should_trade": true,     // score >= threshold
  "confidence": 0.156,      // Model uncertainty (optional)
  "latency_ms": 12.5,       // Processing time
  "model_version": "1.0.0", // Model identifier
  "timestamp": "2025-01-15T10:30:45Z"
}
```

#### Error Handling

```json
// HTTP 400 - Bad Request
{
  "error": "Invalid input",
  "detail": "Expected 80 features, received 75"
}

// HTTP 500 - Server Error
{
  "error": "Prediction failed",
  "detail": "Model file not found"
}

// HTTP 503 - Service Unavailable
{
  "error": "Service unavailable",
  "detail": "Model loading in progress"
}
```

**MQL5 Fallback Logic**:
```cpp
if(http_status != 200) {
   Print("ML API error: ", http_status, " - using fallback");
   return m_fallbackScorer.ScoreSignal(signal, analyzer);
}

if(json_parse_failed) {
   Print("ML API response invalid - using fallback");
   return m_fallbackScorer.ScoreSignal(signal, analyzer);
}

if(latency > 500) {
   Print("ML API too slow (", latency, "ms) - using fallback");
   m_apiHealthy = false;
   return m_fallbackScorer.ScoreSignal(signal, analyzer);
}
```

---

## Model Training & Deployment

### Training Pipeline

```
Step 1: Data Collection
├── Run EA in Strategy Tester (1-3 years)
├── C_DataCollector logs every signal + outcome
└── Export to CSV (features + labels)

Step 2: Data Preparation
├── Load CSV in Python
├── Clean data (remove NaN, outliers)
├── Train/Val/Test split (70/15/15)
└── Normalize features (StandardScaler)

Step 3: Model Training
├── Train XGBoost classifier
├── Hyperparameter tuning (GridSearch)
├── Cross-validation (5-fold)
└── Early stopping on validation set

Step 4: Model Evaluation
├── Test set performance
├── ROC curves, confusion matrix
├── Feature importance analysis
└── Validation gates (accuracy >60%, AUC >0.65)

Step 5: Model Export
├── Save model: joblib.dump()
├── Save scaler: joblib.dump()
└── Version control (Git tag)

Step 6: Deployment
├── Copy model files to API server
├── Restart FastAPI service
└── Health check verification
```

### Continuous Learning Loop

```
Weekly Retraining Process:
1. Collect new trade data from live EA (C_DataCollector)
2. Append to existing training dataset
3. Retrain model with updated data
4. Validate performance on recent out-of-sample period
5. If improvement > 2%, deploy new model
6. Monitor performance for 1 week
7. If performance degrades, rollback to previous version
```

**Monitoring Metrics**:
- Prediction accuracy (actual wins vs predicted)
- Calibration (predicted probabilities vs actual frequencies)
- Feature drift (distribution changes over time)
- Model latency

---

## Risk Mitigation Strategy

### Overfitting Prevention

> [!CAUTION]
> **Critical Risk: Model Overfitting**
> 
> This is the **#1 reason ML trading systems fail in live markets**. Our mitigation strategy:

**1. Walk-Forward Validation**
```
Train Period 1: 2022-01-01 to 2022-12-31 → Test Period 1: 2023-01-01 to 2023-03-31
Train Period 2: 2022-04-01 to 2023-03-31 → Test Period 2: 2023-04-01 to 2023-06-30
Train Period 3: 2022-07-01 to 2023-06-30 → Test Period 3: 2023-07-01 to 2023-09-30
...
```
Model must perform well on **all** test periods, not just cumulative backtest.

**2. Multiple Instrument Validation**
- Train on combined dataset: EURUSD + GBPUSD + GOLD
- Test individually on each instrument
- Model must generalize across instruments

**3. Regularization Techniques**
```python
XGBClassifier(
    max_depth=5,              # Limit tree depth
    min_child_weight=3,       # Minimum samples per leaf
    reg_alpha=0.1,            # L1 regularization
    reg_lambda=1.0,           # L2 regularization
    subsample=0.8,            # Row sampling
    colsample_bytree=0.8,     # Feature sampling
)
```

**4. Simplicity First**
- Start with fewer features (20-30 most important)
- Use simple models before complex (Logistic Regression → Random Forest → XGBoost → Neural Networks)
- Avoid deep learning unless simpler models fail

**5. Long Demo Period**
- Minimum **6-8 weeks** of demo trading
- Must match backtest performance within 20%
- If fails, do NOT proceed to live

---

### API Reliability

**High Availability Strategy**:

1. **Fallback to ML-Lite**: Always works even if API fails
2. **Health Monitoring**: Check API every 1 minute, mark unhealthy if 3 consecutive failures
3. **Timeout Protection**: Hard timeout at 1 second, use fallback if exceeded
4. **Retry Logic**: Retry failed API calls once after 500ms
5. **Local Deployment**: Run API server on same machine as MT5 for lowest latency

**Monitoring**:
```cpp
// In EA OnTimer (every 1 minute)
if(!m_mlClient.CheckHealth()) {
   Print("WARNING: ML API unhealthy, using fallback logic");
   SendNotification("ML API down - EA using fallback");
}
```

---

### Model Drift Detection

**Concept**: Markets change, models become stale

**Detection Methods**:
1. **Performance Monitoring**: Track actual win rate vs predicted
2. **Feature Distribution**: Compare live feature distributions to training data
3. **Prediction Calibration**: Predicted 70% win rate should result in ~70% actual wins

**Response**:
- If accuracy drops >10% below expected: Trigger warning
- If accuracy drops >15%: Auto-retrain with recent data
- If accuracy drops >20%: Pause ML, revert to ML-Lite until fixed

**Automatic Alerts**:
```python
# In monitoring script
if actual_win_rate < predicted_win_rate - 0.10:
    send_email("Model drift detected - accuracy degraded")
    trigger_retraining()
```

---

## Technology Stack Summary

### MQL5 Components (LulaMultiInstrumentEA)

| Component | File | Purpose |
|-----------|------|---------|
| Signal Scorer | `Core/ML/C_SignalScorer.mqh` | ML-Lite rule-based scoring |
| ML Client | `Core/ML/C_MLClient.mqh` | API communication, fallback logic |
| Data Collector | `Core/ML/C_DataCollector.mqh` | Training data collection |
| Feature Extractor | `Core/ML/C_FeatureExtractor.mqh` | Convert market state to features |
| Strategy Integration | `Core/Strategies/C_*Strategy.mqh` | Use ML scores in trading logic |

### Python Components (LulaML_Service)

| Component | Technology | Purpose |
|-----------|-----------|---------|
| API Server | FastAPI + Uvicorn | REST API for predictions |
| ML Model | XGBoost / LightGBM | Signal quality classifier |
| Training Pipeline | scikit-learn + pandas | Data prep and model training |
| Model Storage | joblib | Serialize/deserialize models |
| Monitoring | Python logging | Track API performance |

### Infrastructure

| Component | Options | Recommendation |
|-----------|---------|----------------|
| **API Hosting** | Local machine, VPS, cloud | Start local, move to VPS if needed |
| **API Server** | Local (localhost:8000) | Lowest latency for testing |
| **Production** | VPS with static IP | Reliability for live trading |
| **Monitoring** | Log files, dashboard | Simple logs initially |
| **Model Versioning** | Git + tags | Track model performance by version |

---

## Next Steps

### Immediate Actions

> [!IMPORTANT]
> **Before Starting Implementation**
> 
> 1. ✅ **Review this architecture** - Provide feedback on design decisions
> 2. ✅ **Test WebRequest** - Verify your broker allows external API calls
> 3. ✅ **Approve phased approach** - Confirm ML-Lite → True ML strategy
> 4. ✅ **Prepare environment** - Install Python 3.8+ if planning to proceed to Phase 1
> 5. ✅ **Allocate time** - Confirm 10-15 hours/week availability for first 12 weeks

### Decision Points

**Option A: Start with Phase 0 (ML-Lite)** ← Recommended
- Low risk, quick wins (2-4 weeks)
- No external dependencies
- Immediate performance improvement
- Foundation for Phase 1

**Option B: Skip to Phase 1 (True ML)**
- Higher risk, longer timeline (8-12 weeks)
- Requires Python expertise
- Greater long-term potential
- Skip if resources limited

**My Recommendation**: **Start with Option A**, validate improvement, then proceed to Phase 1

---

## Appendix: Comparison with Original Plan

| Aspect | Original Plan (v1.0) | Revised Plan (v2.0) |
|--------|---------------------|-------------------|
| **Timeline** | 10 weeks | 24-28 weeks |
| **Approach** | Direct ML implementation | Phased: ML-Lite → True ML |
| **Integration** | Local ONNX models | Python REST API |
| **Expected Win Rate** | 65-75% | 55-60% initially, 65-70% long-term |
| **Risk** | High (overfitting, timeline) | Lower (incremental, validated) |
| **First Deliverable** | Week 6 (data + model) | Week 4 (ML-Lite working) |
| **Fallback Logic** | Mentioned but not detailed | Comprehensive fallback to ML-Lite |
| **Validation** | Single phase | Multi-gate validation |

**Key Improvements**:
- ✅ More realistic timeline
- ✅ Incremental value delivery
- ✅ Lower risk of failure
- ✅ Better fallback mechanisms
- ✅ Clearer validation gates
- ✅ Conservative performance expectations

---

**Questions or clarifications needed?** Let me know if any aspect of this architecture needs further detail or adjustment!
