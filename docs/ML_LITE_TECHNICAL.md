# ML-Lite Technical Documentation

**Version**: 1.1  
**Last Updated**: January 21, 2026  
**Audience**: Developers & Advanced Users

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Component Reference](#component-reference)
3. [API Documentation](#api-documentation)
4. [Integration Guide](#integration-guide)
5. [Data Structures](#data-structures)
6. [File Formats](#file-formats)
7. [Performance Considerations](#performance-considerations)
8. [Extension Points](#extension-points)

---

## System Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────┐
│         LulaEA_Automated (Main EA)          │
└─────────────────┬───────────────────────────┘
                  │
      ┌───────────┴────────────┬──────────────┐
      ▼                        ▼              ▼
┌─────────────┐      ┌──────────────────┐  ┌────────────────────┐
│ SignalScorer│      │  DataCollector   │  │ PerformanceTracker │
│  (Scoring)  │      │  (CSV Logging)   │  │   (Analytics)      │
└──────┬──────┘      └────────┬─────────┘  └─────────┬──────────┘
       │                      │                       │
       │ ScoreSignal()        │ LogSignal()          │ RecordSignal()
       │      ↓               │      ↓               │      ↓
       └──────┴───────────────┴──────┴───────────────┴──────┘
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
              CSV Files          In-Memory Metrics
          (ML_Data/*.csv)       (Tiers, Drawdown)
```

### Component Responsibilities

| Component | Purpose | Size | Dependencies |
|-----------|---------|------|--------------|
| C_SignalScorer | Evaluate signal quality (0.0-1.0) | 1,200 lines | IndicatorHelpers |
| C_DataCollector | Log signals to CSV with 40+ features | 905 lines | C_SignalScorer |
| C_PerformanceTracker | Track metrics by score tier | 650 lines | None |

### Data Flow

```
1. Trading Signal Detected (CheckForNewTrade)
   ↓
2. C_SignalScorer::EvaluateSignal()
   → Returns SignalScore struct
   ↓
3. C_DataCollector::LogSignal()
   → Writes to CSV
   ↓
4. C_PerformanceTracker::RecordSignal()
   → Updates tier metrics
   ↓
5. ML-Lite Filtering Logic
   ├─ IF score < threshold → Skip trade
   └─ ELSE → Execute trade
   ↓
6. (Later) C_PerformanceTracker::RecordOutcome()
   → Update win/loss by tier
```

---

## Component Reference

### C_SignalScorer

**Location**: `Core/ML/C_SignalScorer.mqh`  
**Purpose**: Evaluates signal quality using 40 scoring factors across 5 categories  
**Thread-Safe**: Yes  
**State**: Stateless (can be shared)

**Initialization**:
```cpp
C_SignalScorer scorer;
if(!scorer.Initialize())
{
   Print("Scorer initialization failed");
   return false;
}
```

**Key Methods**:
- `Initialize()` - Must be called once
- `EvaluateSignal()` - Main scoring function
- `UpdateWeights()` - Adjust factor weights (advanced)

### C_DataCollector

**Location**: `Core/ML/C_DataCollector.mqh`  
**Purpose**: Log signals with features to CSV files  
**Thread-Safe**: No (file I/O)  
**State**: Maintains file handle

**Initialization**:
```cpp
C_DataCollector collector;
if(!collector.Initialize("ML_Data", 50, 60))
{
   Print("Collector initialization failed");
   return false;
}
```

**Key Methods**:
- `Initialize(path, maxSizeMB, flushMin)` - Setup
- `LogSignal()` - Write signal to CSV
- `LogOutcome()` - Update trade result (WIN/LOSS/MFE/MAE)
- `UpdateMFE_MAE()` - Track running P/L during trade
- `PeriodicFlush()` - Save to disk
- `Shutdown()` - Clean close

### C_PerformanceTracker

**Location**: `Core/ML/C_PerformanceTracker.mqh`  
**Purpose**: Track performance metrics by score tier  
**Thread-Safe**: Yes  
**State**: Maintains tier metrics in memory

**Initialization**:
```cpp
C_PerformanceTracker tracker;
if(!tracker.Initialize("ML_Data", 0.70, 0.50))
{
   Print("Tracker initialization failed");
   return false;
}
```

**Key Methods**:
- `Initialize(path, highThresh, medThresh)` - Setup
- `RecordSignal(score, taken)` - Log signal
- `RecordOutcome(score, isWin, pips)` - Log result
- `GetSnapshot()` - Get current metrics
- `GenerateDashboard()` - Create report
- `IsScoreCalibrated()` - Check accuracy

---

## API Documentation

### C_SignalScorer::EvaluateSignal()

**Signature**:
```cpp
SignalScore EvaluateSignal(
   string symbol,
   ENUM_TIMEFRAMES timeframe,
   int direction,              // OP_BUY or OP_SELL
   double stopLoss,
   double takeProfit
)
```

**Parameters**:
- `symbol`: Trading symbol (e.g., "EURUSD")
- `timeframe`: Signal timeframe (e.g., PERIOD_M15)
- `direction`: Trade direction (OP_BUY or OP_SELL)
- `stopLoss`: Planned stop loss price
- `takeProfit`: Planned take profit price

**Returns**: `SignalScore` struct containing:
```cpp
struct SignalScore
{
   double score;                    // 0.0-1.0 overall score
   SignalRecommendation recommendation; // TAKE/CONSIDER/SKIP
   
   // Factor scores (0.0-1.0 each)
   double trendScore;
   double technicalScore;
   double contextScore;
   double rrScore;
   double historicalScore;
   
   // Weights applied
   double trendWeight;
   double technicalWeight;
   double contextWeight;
   double rrWeight;
   double historicalWeight;
};
```

**Usage Example**:
```cpp
SignalScore score = g_SignalScorer.EvaluateSignal(
   _Symbol,           // "EURUSD"
   PERIOD_M15,        // M15 timeframe
   OP_BUY,            // Buy signal
   1.08500,           // SL price
   1.09500            // TP price
);

PrintFormat("Score: %.4f, Recommendation: %s", 
            score.score, 
            EnumToString(score.recommendation));
```

### C_DataCollector::LogSignal()

**Signature**:
```cpp
string LogSignal(
   SignalScore score,
   string symbol,
   ENUM_TIMEFRAMES timeframe,
   int direction,
   double entryPrice,
   double stopLoss,
   double takeProfit
)
```

**Returns**: Trade ID string (e.g., "20260107_010530_123")

**Side Effects**:
- Writes row to CSV file
- Extracts 30+ indicator features
- Flushes if interval elapsed

**Usage Example**:
```cpp
string tradeId = g_DataCollector.LogSignal(
   score,             // From EvaluateSignal()
   _Symbol,
   PERIOD_M15,
   OP_BUY,
   1.09000,           // Entry price
   1.08500,           // SL
   1.09500            // TP
);

Print("Logged signal: ", tradeId);
```

### C_PerformanceTracker::RecordSignal()

**Signature**:
```cpp
void RecordSignal(
   double score,
   bool wasTaken
)
```

**Parameters**:
- `score`: Signal score (0.0-1.0)
- `wasTaken`: true if trade executed, false if filtered

**Updates**:
- Appropriate tier's signal count
- Overall signal count
- Derived metrics (take rate, etc.)

**Usage Example**:
```cpp
// Before filtering decision
g_PerformanceTracker.RecordSignal(score.score, false);

// After decision to take trade
if(score.score >= threshold)
{
   g_PerformanceTracker.RecordSignal(score.score, true);
   // Execute trade...
}
```

### C_PerformanceTracker::RecordOutcome()

**Signature**:
```cpp
void RecordOutcome(
   double score,
   bool isWin,
   double profitPips
)
```

**Parameters**:
- `score`: Original signal score
- `isWin`: true if profitable, false if loss
- `profitPips`: Profit/loss in pips (positive or negative)

**Updates**:
- Win/loss count for tier
- Profit/loss totals
- Largest win/loss
- Win rate, PF, expectancy

**Usage Example**:
```cpp
// On trade close
double pips = (closePrice - entryPrice) / _Point;
bool isWin = (pips > 0);

g_PerformanceTracker.RecordOutcome(
   originalScore,     // Score from signal
   isWin,
   pips
);
```

### C_DataCollector::LogOutcome()

**Signature**:
```cpp
bool LogOutcome(
   string tradeId,
   TradeOutcome outcome
)
```

**Parameters**:
- `tradeId`: Signal ID returned from LogSignal()
- `outcome`: TradeOutcome struct with result data

**TradeOutcome Structure**:
```cpp
struct TradeOutcome
{
   string tradeId;          // Must match original signal ID
   bool executed;           // Was trade actually executed?
   
   // Entry details
   double actualEntry;      // Actual entry price
   datetime entryTime;      // Entry timestamp
   
   // Performance metrics
   double mfe;              // Max Favorable Excursion (pips)
   double mae;              // Max Adverse Excursion (pips)
   
   // Exit details
   double exitPrice;        // Closing price
   datetime exitTime;       // Exit timestamp
   double profitPips;       // Final P/L in pips
   double profitCurrency;   // Final P/L in account currency
   
   // Classification
   string outcome;          // "WIN", "LOSS", or "BREAKEVEN"
   string exitReason;       // "TP", "SL", "MANUAL", etc.
};
```

**Returns**: `true` if outcome logged successfully, `false` on error

**Side Effects**:
- Updates CSV row with outcome data
- Writes to file immediately or buffers
- Logs confirmation message

**Usage Example**:
```cpp
// When position closes
TradeOutcome outcome;
outcome.tradeId = originalTradeId;      // From LogSignal()
outcome.executed = true;
outcome.actualEntry = 1.09000;
outcome.entryTime = TimeCurrent();
outcome.exitPrice = 1.09450;
outcome.exitTime = TimeCurrent();
outcome.profitPips = 45.0;
outcome.profitCurrency = 112.50;
outcome.mfe = 52.1;                     // Best profit seen
outcome.mae = -8.3;                     // Worst drawdown
outcome.outcome = "WIN";
outcome.exitReason = "TP";

bool success = g_DataCollector.LogOutcome(originalTradeId, outcome);
if(success)
{
   Print("Logged outcome: ", outcome.outcome);
}
```

### C_DataCollector::UpdateMFE_MAE()

**Signature**:
```cpp
void UpdateMFE_MAE(
   string tradeId,
   double currentPrice,
   int direction
)
```

**Parameters**:
- `tradeId`: Signal ID from LogSignal()
- `currentPrice`: Current market price  
- `direction`: `OP_BUY` or `OP_SELL` (trade direction)

**Purpose**: Continuously tracks the best and worst unrealized P/L during an open trade

**Algorithm**:
1. Calculate current unrealized P/L in pips
2. If P/L > current MFE → update MFE
3. If P/L < current MAE → update MAE
4. Store in memory (written to CSV on position close)

**Call Frequency**: Every tick for open positions

**Usage Example**:
```cpp
// In OnTick() - track all open positions
for(int i = 0; i < ArraySize(g_ActiveTrades); i++)
{
   if(PositionSelectByTicket(g_ActiveTrades[i].ticket))
   {
      double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      
      g_DataCollector.UpdateMFE_MAE(
         g_ActiveTrades[i].tradeId,    // Signal ID
         currentPrice,                  // Current price
         g_ActiveTrades[i].direction    // OP_BUY or OP_SELL
      );
   }
}
```

**MFE/MAE Interpretation**:
- **High MFE, Low MAE**: Trade went in your favor quickly (good)
- **Low MFE, High MAE**: Trade struggled, eventual profit was lucky
- **High MFE, High MAE**: Trade had large swings (volatility)
- **Low MFE, Low MAE**: Trade stayed near entry (tight stop or quick exit)

---

## Integration Guide

### Minimal Integration

**Required components**:
1. C_SignalScorer (scoring only)
2. C_DataCollector (optional, for logging)

```cpp
// Global variables
C_SignalScorer g_Scorer;

// In OnInit()
if(!g_Scorer.Initialize())
   return INIT_FAILED;

// In CheckForNewTrade()
SignalScore score = g_Scorer.EvaluateSignal(
   _Symbol, PERIOD_M15, OP_BUY, sl, tp
);

if(score.score >= 0.60)
{
   // Execute trade
}
```

### Full ML-Lite Integration

**All components** + filtering + tracking:

```cpp
// Global variables
C_SignalScorer g_Scorer;
C_DataCollector g_Collector;
C_PerformanceTracker g_Tracker;

// Input parameters
input bool InpMLLiteEnabled = true;
input double InpMLScoreThreshold = 0.60;

// In OnInit()
if(!g_Scorer.Initialize()) return INIT_FAILED;
if(!g_Collector.Initialize()) return INIT_FAILED;
if(!g_Tracker.Initialize()) return INIT_FAILED;

// In OnTick()
g_Collector.PeriodicFlush();

// In CheckForNewTrade()
SignalScore score = g_Scorer.EvaluateSignal(...);

// Log signal
string tradeId = g_Collector.LogSignal(...);
g_Tracker.RecordSignal(score.score, false);

// Filter check
if(InpMLLiteEnabled && score.score < InpMLScoreThreshold)
{
   Print("Signal filtered");
   return;
}

// Update tracker
g_Tracker.RecordSignal(score.score, true);

// Execute trade...

// In OnDeinit()
g_Collector.Shutdown();
g_Tracker.Shutdown();
```

### Custom Strategy Integration

**Using ML-Lite with your own logic**:

```cpp
// Your custom signal detection
if(MyCustomLogic())
{
   // Use ML-Lite for validation
   SignalScore score = g_Scorer.EvaluateSignal(...);
   
   // Apply your own threshold
   if(score.score >= MyThreshold)
   {
      // Your execution logic
      PlaceOrder();
   }
}
```

---

## Data Structures

### SignalScore

```cpp
struct SignalScore
{
   double score;                      // Overall score (0.0-1.0)
   SignalRecommendation recommendation; // TAKE/CONSIDER/SKIP
   
   // Individual factor scores
   double trendScore;
   double technicalScore;
   double contextScore;
   double rrScore;
   double historicalScore;
   
   // Weights used
   double trendWeight;
   double technicalWeight;
   double contextWeight;
   double rrWeight;
   double historicalWeight;
};
```

### TierMetrics

```cpp
struct TierMetrics
{
   // Signal tracking
   int signalsGenerated;
   int signalsTaken;
   int signalsSkipped;
   
   // Trade outcomes
   int wins;
   int losses;
   int breakevens;
   
   // P/L tracking
   double totalProfit;
   double totalLoss;
   double largestWin;
   double largestLoss;
   
   // Derived metrics
   double winRate;
   double profitFactor;
   double avgWin;
   double avgLoss;
   double expectancy;
   double takeRate;
};
```

### PerformanceSnapshot

```cpp
struct PerformanceSnapshot
{
   datetime snapshotTime;
   
   TierMetrics highScoreTier;
   TierMetrics mediumScoreTier;
   TierMetrics lowScoreTier;
   TierMetrics overall;
   
   double currentDrawdown;
   double maxDrawdown;
   double sharpeRatio;
   double recoveryFactor;
   
   bool isCalibrated;
   double calibrationScore;
};
```

---

## File Formats

### CSV Signal Log

**File**: `ML_Data/signals_YYYY-MM.csv`  
**Format**: CSV with header  
**Encoding**: ANSI  
**Rotation**: Monthly

**Columns** (51 total):

**Metadata** (11):
- TradeID, Symbol, Timeframe, Direction
- Timestamp, EntryPrice, StopLoss, TakeProfit
- OverallScore, Recommendation, ScoreTier

**Features** (30):
- Trend: ADX, ATR_Norm, HTF_Trend, MTF_Trend, etc.
- Momentum: RSI, MACD, Stochastic, ROC, etc.
- Volatility: ATR, HistVol, BB_Width, etc.
- Price Action: HH_Distance, LL_Distance, etc.
- Context: Session, Hour, Spread, etc.

**Outcomes** (10):
- ActualOutcome, ClosePrice, ExitTime
- ProfitPips, MFE, MAE, Duration, etc.

**Example Row**:
```csv
20260107_010530_123,EURUSD,M15,BUY,2026.01.07 01:05:30,1.09000,1.08500,1.09500,0.6842,SIGNAL_TAKE,MEDIUM,25.3,0.00125,1,...
```

---

## Performance Considerations

### Memory Usage

**Per component**:
- C_SignalScorer: ~10 KB (indicator handles)
- C_DataCollector: ~5 KB + file buffer
- C_PerformanceTracker: ~2 KB (metrics)

**Total overhead**: < 20 KB per EA instance

### CPU Impact

**Per signal**:
- Scoring: ~2-5ms
- Feature extraction: ~3-8ms
- CSV write: ~1-2ms
- **Total**: < 15ms per signal

**Recommendations**:
- Flush interval >= 60 minutes
- Max file size <= 100 MB
- Use SSD for data directory

### Disk I/O

**Write patterns**:
- CSV: Append-only, buffered
- Flush: Every 60 minutes (configurable)
- Rotation: Monthly (automatic)

**Disk usage**:
- ~1 MB per 1,000 signals
- ~30 MB per month (active trading)

---

## Extension Points

### Custom Scoring Factors

Add your own factors to C_SignalScorer:

```cpp
// In C_SignalScorer class
double MyCustomFactor(string symbol, ENUM_TIMEFRAMES tf)
{
   // Your logic here
   return score; // 0.0-1.0
}

// In EvaluateSignal()
double customScore = MyCustomFactor(symbol, timeframe);
finalScore += customScore * customWeight;
```

### Custom Features

Add features to C_DataCollector:

```cpp
// In ExtractFeatures()
features += StringFormat(",%.5f", MyCustomIndicator());
```

Remember to update CSV header!

### Custom Metrics

Add metrics to C_PerformanceTracker:

```cpp
// In TierMetrics struct
double myCustomMetric;

// In CalculateDerivedMetrics()
tier.myCustomMetric = CalculateMyMetric(tier);

// In GenerateDashboard()
dashboard += StringFormat("  My Metric: %.2f\n", 
                          m_highTier.myCustomMetric);
```

### Event Hooks

Add hooks for custom logic:

```cpp
// After scoring
virtual void OnSignalScored(SignalScore& score)
{
   // Your custom logic
}

// Before filtering
virtual bool OnBeforeFilter(double score)
{
   // Return false to skip default filtering
   return true;
}

// After trade execution
virtual void OnTradeExecuted(string tradeId, double score)
{
   // Your tracking logic
}
```

---

## Version History

- v1.1 (2026-01-21): Added outcome tracking (LogOutcome, UpdateMFE_MAE), updated to 40+ features, enhanced API documentation
- v1.0 (2026-01-07): Initial release

---

## See Also

- [ML-Lite User Guide](ML_LITE_USER_GUIDE.md) - For end users
- [Parameter Tuning Guide](ML_LITE_TUNING_GUIDE.md) - Optimization guide
- [CSV Analysis Tools](../Tools/README.md) - Python utilities
