# Phase 0: ML-Lite Foundation - Task Breakdown

**Timeline**: 4 Weeks (Jan 5 - Feb 2, 2026)  
**Status**: 🚀 Ready to Start

---

## Week 1: Foundation & Signal Scorer (Jan 5-12)

### Core Development
- [ ] Create `Core/ML/C_SignalScorer.mqh` file structure
- [ ] Define `struct SignalScore` with fields: score, confidence, factors, recommendation
- [ ] Define `struct ScoringFactors` with individual factor breakdowns
- [ ] Implement C_SignalScorer class skeleton

### Scoring Factors - Trend Alignment (25% weight)
- [ ] HTF-LTF trend agreement scoring (0.0-1.0)
- [ ] Trend strength scoring using ADX
- [ ] Trend consistency calculation
- [ ] Trend duration factor
- [ ] Multi-timeframe confluence checker

### Scoring Factors - Technical Confirmation (25% weight)
- [ ] Support/Resistance proximity scoring
- [ ] Moving average alignment (multiple MAs)
- [ ] RSI confirmation logic
- [ ] MACD alignment scoring
- [ ] Price action pattern recognition

### Scoring Factors - Market Context (20% weight)
- [ ] Volatility appropriateness (ATR-based)
- [ ] Session timing scoring (London/NY overlap bonus)
- [ ] Spread favorability check
- [ ] Market regime detection (trending vs ranging)
- [ ] Economic calendar impact (placeholder for now)

### Scoring Factors - Risk/Reward Setup (15% weight)
- [ ] R:R ratio quality scorer
- [ ] Stop loss placement logic validation
- [ ] Take profit placement logic validation
- [ ] Position within trading range
- [ ] Distance from key levels assessment

### Scoring Factors - Historical Performance (15% weight)
- [ ] Similar setup tracker (basic implementation)
- [ ] Time-of-day performance lookup
- [ ] Symbol-specific performance
- [ ] Pattern frequency counter
- [ ] Recent performance trend analyzer

### Integration & Testing
- [ ] Implement weight system (factors sum to 1.0)
- [ ] Create score aggregation logic
- [ ] Add confidence calculation
- [ ] Implement recommendation logic (STRONG_TAKE/TAKE/CONSIDER/SKIP)
- [ ] Write unit tests for each factor (50+ test cases)
- [ ] Validate score ranges (must be 0.0-1.0)
- [ ] Test scoring with historical data

### Documentation
- [ ] Document each scoring factor methodology
- [ ] Create examples of score calculations
- [ ] Document weight tuning guidelines

**Week 1 Deliverable**: ✅ Fully functional signal scorer with all 20 factors

---

## Week 2: Data Collection & Integration (Jan 13-19)

### C_DataCollector Implementation
- [ ] Create `Core/ML/C_DataCollector.mqh` file
- [ ] Implement CSV file manager
- [ ] Create data directory structure (`data/signals_YYYY-MM.csv`)
- [ ] Implement feature extraction (30+ technical indicators)
- [ ] Create signal logging function
- [ ] Create outcome logging function
- [ ] Implement monthly file rotation
- [ ] Add data validation & error handling

### Feature Engineering
- [ ] Define complete feature list (30+ features)
- [ ] Implement trend features (ADX, ATR, MA slopes, etc.)
- [ ] Implement momentum features (RSI, MACD, Stochastic, ROC)
- [ ] Implement volatility features (ATR, Bollinger, historical vol)
- [ ] Implement price action features (patterns, S/R, etc.)
- [ ] Implement market context features (session, spread, volume)
- [ ] Implement multi-timeframe features (HTF trend, LTF conf)

### Trade Tracking
- [ ] Implement trade ID generation
- [ ] Link signal to trade execution
- [ ] Track trade lifecycle (entry → exit)
- [ ] Log max favorable excursion (MFE)
- [ ] Log max adverse excursion (MAE)
- [ ] Log final outcome (win/loss/breakeven)

### EA Integration
- [ ] Include C_DataCollector in main EA
- [ ] Initialize collector in OnInit()
- [ ] Hook into signal generation logic
- [ ] Hook into trade entry execution
- [ ] Hook into trade exit/close
- [ ] Add flush-to-file on EA shutdown
- [ ] Implement periodic auto-save (every hour)

### Testing & Validation
- [ ] Test CSV file creation
- [ ] Validate CSV format & headers
- [ ] Test feature extraction accuracy
- [ ] Test across multiple timeframes
- [ ] Test across multiple symbols
- [ ] Verify data integrity
- [ ] Test file rotation (simulate month change)
- [ ] Load test (1000+ signals)

### Configuration
- [ ] Add `InpMLDataCollection` parameter (bool)
- [ ] Add configurable data directory path
- [ ] Add maximum file size limits
- [ ] Add data retention settings

**Week 2 Deliverable**: ✅ Data collection operational, CSV files generating with valid data

---

## Week 3: Performance Tracking & ML-Lite Integration (Jan 20-26)

### C_PerformanceTracker Implementation
- [ ] Create `Core/ML/C_PerformanceTracker.mqh` file
- [ ] Implement metrics calculation engine
- [ ] Create score tier analyzer (high/med/low)
- [ ] Implement win rate by score tier
- [ ] Implement profit factor by score tier
- [ ] Create dashboard generation function
- [ ] Implement file logging for metrics
- [ ] Add real-time metric updates

### Metrics & Analytics
- [ ] Track signals generated (by score range)
- [ ] Track signals taken vs skipped
- [ ] Track score distribution histogram
- [ ] Calculate overall win rate
- [ ] Calculate win rate by score tier
- [ ] Calculate profit factor overall & by tier
- [ ] Calculate average win/loss
- [ ] Calculate max drawdown
- [ ] Calculate Sharpe ratio
- [ ] Calculate recovery factor
- [ ] Track score calibration accuracy

### Dashboard Development
- [ ] Design dashboard layout (text format)
- [ ] Implement 7-day lookback summary
- [ ] Add 30-day performance comparison
- [ ] Create CSV export for metrics
- [ ] Add chart annotations (optional)

### Full ML-Lite Integration
- [ ] Add input parameters (thresholds, multipliers, weights)
- [ ] Initialize all ML components in OnInit()
- [ ] Integrate scorer into signal validation
- [ ] Implement score-based filtering logic
- [ ] Implement risk scaling (high/med score risk multipliers)
- [ ] Add fallback to original behavior (killswitch)
- [ ] Log all ML-Lite decisions

### Backward Compatibility
- [ ] Ensure EA works with InpMLLiteEnabled = false
- [ ] Preserve original trading logic
- [ ] Test both modes (ML-Lite ON/OFF)
- [ ] Validate no regression in baseline performance

### Backtesting & Calibration
- [ ] Backtest with different score thresholds (0.5, 0.6, 0.7, 0.8)
- [ ] Backtest with different weight combinations
- [ ] Optimize threshold values
- [ ] Optimize weight factors
- [ ] Validate improvement vs baseline
- [ ] A/B test different configurations

### Testing
- [ ] Integration test: Full trade lifecycle with ML-Lite
- [ ] Test signal filtering (high/med/low scores)
- [ ] Test risk scaling logic
- [ ] Test performance tracker accuracy
- [ ] Test dashboard generation
- [ ] Edge case testing (no signals, max signals, etc.)
- [ ] Stress test (100+ concurrent signals)

**Week 3 Deliverable**: ✅ Full ML-Lite system operational and integrated

---

## Week 4: Refinement, Validation & Documentation (Jan 27 - Feb 2)

### 🆕 **PRIORITY: Pattern Recognition Enhancement** (2 hours)
- [ ] **[URGENT]** Add missing bullish patterns (HARAMI, PIERCING) to line 266
- [ ] **[URGENT]** Add missing bearish patterns (HARAMI, DARK_CLOUD) to line 267
- [ ] Create `GetPatternStrength()` function (Tier 1/2/3 scoring)
- [ ] Update BUY entry logic to use pattern strength (line 295)
- [ ] Update SELL entry logic to use pattern strength (line 394)
- [ ] Backtest pattern enhancement (expect +30% more signals)
- [ ] **Deliverable:** All 10 Nison patterns utilized

### 🆕 **Dual-Strategy System Implementation** (Days 1-3)

#### **Day 1: Architecture & Strategy Classes**
- [ ] Add `ENUM_STRATEGY_TYPE` and `ENUM_CONFLICT_MODE` to `Lula_CoreEnums.mqh`
- [ ] Create `Core/Strategies/C_DayTradingStrategy.mqh` (H4→H1→M15)
- [ ] Create `Core/Strategies/C_SwingTradingStrategy.mqh` (D1→H4→H1)
- [ ] Implement triple-timeframe confirmation logic for both
- [ ] Add magic number generation system (1000s = day, 2000s = swing)
- [ ] **Deliverable:** Strategy classes compile and implement IStrategy

#### **Day 2: Risk Allocation & Main EA Integration**
- [ ] Add dual-strategy input parameters to `LulaEA_Automated.mq5`
- [ ] Implement `GetDayTradingRisk()` - returns 3% solo, 1.5% when swing active
- [ ] Implement `GetSwingTradingRisk()` - returns 3% solo, 1.5% when day active
- [ ] Implement `HasActivePosition(ENUM_STRATEGY_TYPE)` with magic number check
- [ ] Update `OnInit()` to initialize both strategies
- [ ] Add D1 and H4 timeframes to market analyzer
- [ ] Create `CheckDayTradingSignals()` function (checks on M15 bar)
- [ ] Create `CheckSwingTradingSignals()` function (checks on H1 bar)
- [ ] Implement conflict resolution: `IsAlignedWithSwingTrend()`
- [ ] Refactor `OnTick()` to call both strategy checks
- [ ] **Deliverable:** Both strategies operational, no conflicts

#### **Day 3: ML Integration & Backtesting**
- [ ] Update `C_DataCollector.LogSignal()` to accept strategy name parameter
- [ ] Add strategy column to CSV output
- [ ] Update `C_PerformanceTracker` to track per-strategy metrics
- [ ] Add `StrategyMetrics` struct for day/swing breakdown
- [ ] Update dashboard to show per-strategy performance
- [ ] Backtest Day Trading only (EURUSD Jan 2025)
- [ ] Backtest Swing Trading only (EURUSD Jan 2025)
- [ ] Backtest Both strategies (EURUSD Jan 2025)
- [ ] Multi-symbol validation (EURUSD, GBPUSD, XAUUSD)
- [ ] **Deliverable:** ML tracking includes strategy tags, backtest shows 65%+ WR

### Performance Optimization
- [ ] Profile scoring performance (target <10ms per signal)
- [ ] Optimize factor calculations
- [ ] Reduce memory footprint
- [ ] Optimize CSV I/O operations
- [ ] Cache frequently accessed data
- [ ] Optimize indicator calculations
- [ ] **🆕** Optimize dual-strategy signal checking (avoid duplicate analysis)

### Weight & Threshold Tuning
- [ ] Fine-tune trend alignment weight
- [ ] Fine-tune technical confirmation weight
- [ ] Fine-tune market context weight
- [ ] Fine-tune R:R setup weight
- [ ] Fine-tune historical performance weight
- [ ] Optimize high-confidence threshold (target 0.70)
- [ ] Optimize medium-confidence threshold (target 0.50)
- [ ] Optimize risk multipliers (high vs medium)
- [ ] **🆕** Optimize day/swing strategy conflict resolution mode

### Forward Testing (1 Week Minimum)
- [ ] Deploy to demo account
- [ ] Run ML-Lite EA for 7 days minimum
- [ ] Run baseline EA in parallel (same symbols)
- [ ] Collect performance data
- [ ] Monitor for issues/bugs
- [ ] Track actual vs expected improvements

### Performance Validation
- [ ] Compare ML-Lite vs baseline win rate
- [ ] Compare ML-Lite vs baseline profit factor
- [ ] Compare ML-Lite vs baseline max drawdown
- [ ] Verify >= +5% win rate improvement
- [ ] Verify >= +15% profit factor improvement
- [ ] Verify data quality (100+ signals logged)
- [ ] Validate score calibration

### Documentation - User Guide
- [ ] Write ML-Lite overview
- [ ] Document how signal scoring works
- [ ] Explain scoring factors & weights
- [ ] Document input parameters
- [ ] Create quick start guide
- [ ] Add troubleshooting section
- [ ] Include FAQ
- [ ] **🆕** Document dual-strategy system (day trading vs swing trading)
- [ ] **🆕** Explain dynamic risk allocation (3% vs 1.5%+1.5%)
- [ ] **🆕** Document conflict resolution modes

### Documentation - Technical
- [ ] Document C_SignalScorer API
- [ ] Document C_DataCollector API
- [ ] Document C_PerformanceTracker API
- [ ] Document feature list (all 30+ features)
- [ ] Document CSV data format
- [ ] Create integration examples
- [ ] Document weight tuning process
- [ ] **🆕** Document C_DayTradingStrategy and C_SwingTradingStrategy APIs
- [ ] **🆕** Document magic number system
- [ ] **🆕** Document per-strategy ML tracking

### Documentation - Tuning Guide
- [ ] How to optimize thresholds
- [ ] How to adjust scoring weights
- [ ] How to interpret dashboard metrics
- [ ] Best practices for configuration
- [ ] Common pitfalls to avoid

### Phase 1 Preparation
- [ ] Review collected data for ML readiness
- [ ] Verify >= 1000 signals collected
- [ ] Plan Python ML pipeline
- [ ] Research ML model candidates (XGBoost, LightGBM, etc.)
- [ ] Draft Phase 1 implementation plan
- [ ] Identify Phase 0 → Phase 1 transition steps

### Final Quality Assurance
- [ ] Full regression testing
- [ ] Performance stress test
- [ ] Memory leak check
- [ ] Error handling verification
- [ ] Edge case validation
- [ ] Code review & cleanup
- [ ] Remove debug logging

### Deployment Preparation
- [ ] Create deployment checklist
- [ ] Prepare rollback plan
- [ ] Create monitoring dashboard
- [ ] Setup performance alerts
- [ ] Document escalation procedures

**Week 4 Deliverable**: ✅ Phase 0 complete with **dual-strategy system**, all 10 patterns enabled, validated, documented, production-ready

---

## Success Criteria Checklist

### Technical Completion
- [ ] All 3 components implemented (Scorer, Collector, Tracker)
- [ ] All unit tests passing (50+ tests)
- [ ] Integration tests passing
- [ ] No compilation errors or warnings
- [ ] Backward compatible (works with ML-Lite disabled)
- [ ] **🆕** All 10 candlestick patterns utilized (not just 6)
- [ ] **🆕** Dual-strategy system operational (Day + Swing)
- [ ] **🆕** Dynamic risk allocation working (3% or 1.5%+1.5%)
- [ ] **🆕** Magic number system correctly differentiated
- [ ] **🆕** Conflict resolution preventing opposite signals

### Performance Targets (Validated via Forward Test)
- [ ] Win rate: +5% minimum improvement (target: 65-70% with dual-strategy)
- [ ] Profit factor: +15% minimum improvement
- [ ] Max drawdown: -20% reduction minimum (target: -50% with diversification)
- [ ] Trade count: Within acceptable range (expect +35% with patterns + dual strategies)
- [ ] Data collected: >= 100 signals
- [ ] **🆕** Day trading win rate: >= 60%
- [ ] **🆕** Swing trading win rate: >= 70%
- [ ] **🆕** Strategy correlation: < 0.7 (diversification benefit)

### Documentation Complete
- [ ] User guide written
- [ ] Technical API docs complete
- [ ] Tuning guide available
- [ ] Integration examples provided
- [ ] Known limitations documented

### Quality Assurance
- [ ] No critical bugs
- [ ] No memory leaks
- [ ] Acceptable performance (<10ms scoring overhead)
- [ ] Error handling comprehensive
- [ ] Logging appropriate (not excessive)

### Phase 1 Readiness
- [ ] Data format validated for ML
- [ ] >= 1000 signals collected
- [ ] Phase 1 plan drafted
- [ ] Team ready for next phase

---

## Risk Register

### Active Risks (Monitor Weekly)

| ID | Risk | Mitigation | Owner | Status |
|----|------|------------|-------|--------|
| R1 | Over-filtering signals | A/B test thresholds | Dev | 🟡 Monitor |
| R2 | Poor score calibration | Extensive backtesting | Dev | 🟡 Monitor |
| R3 | Performance overhead | Profile & optimize | Dev | 🟢 Low |
| R4 | Data corruption | Validation & backup | Dev | 🟢 Low |
| R5 | Regression vs baseline | Continuous comparison | Dev | 🟡 Monitor |
| R6 | User adoption | Clear docs & benefits | Product | 🟢 Low |

---

## Weekly Milestones

### Week 1 Gate
- **Criteria**: Signal scorer fully functional with all 20 factors
- **Evidence**: Unit tests passing, backtested successfully
- **Decision**: Proceed to Week 2 ✅ / Iterate ❌

### Week 2 Gate
- **Criteria**: Data collection generating valid CSV files
- **Evidence**: 50+ signals logged, data validated
- **Decision**: Proceed to Week 3 ✅ / Iterate ❌

### Week 3 Gate
- **Criteria**: ML-Lite fully integrated and backtested
- **Evidence**: Backtest shows +10% profit factor improvement
- **Decision**: Proceed to Week 4 (forward test) ✅ / Iterate ❌

### Week 4 Gate (Final)
- **Criteria**: Forward test validates improvements >= targets
- **Evidence**: 7-day forward test shows +5% win rate, +15% PF
- **Decision**: Ship Phase 0 ✅ / Extend testing ⏸️ / Rollback ❌

---

## Progress Tracking

### Daily Standup Questions
1. What did I complete yesterday?
2. What will I work on today?
3. Any blockers or risks?

### Weekly Review
1. Tasks completed this week
2. Tasks remaining
3. On track for milestone?
4. Any scope changes?
5. Risks identified?

### Metrics Dashboard (Update Weekly)
```
Phase 0 Progress: XX%
- Week 1: [███████░░░] 70%
- Week 2: [░░░░░░░░░░] 0%
- Week 3: [░░░░░░░░░░] 0%
- Week 4: [░░░░░░░░░░] 0%

Components:
- C_SignalScorer: XX% complete
- C_DataCollector: XX% complete
- C_PerformanceTracker: XX% complete

Testing:
- Unit Tests: XX/50 passing
- Integration Tests: XX/10 passing
- Forward Test: Day X/7

Performance vs Baseline:
- Win Rate: +XX%
- Profit Factor: +XX%
- Signals Collected: XXX
```

---

## Next Immediate Actions

### This Week (Week 1 Start - Jan 5-6)
1. [ ] Review and approve Phase 0 plan
2. [ ] Create C_SignalScorer.mqh file
3. [ ] Define struct SignalScore and ScoringFactors
4. [ ] Implement first 5 scoring factors (trend alignment)
5. [ ] Write unit tests for trend scoring

### Tomorrow (First Development Day)
- [ ] Morning: Setup development environment
- [ ] Morning: Create file structure for Phase 0 components
- [ ] Afternoon: Implement SignalScore struct & basic class skeleton
- [ ] Afternoon: Start implementing trend alignment factors
- [ ] Evening: Write first unit tests

---

**Task Breakdown Created**: January 5, 2026  
**Phase 0 Start**: January 5, 2026  
**Phase 0 Target End**: February 2, 2026  
**Status**: ✅ **READY TO BEGIN WEEK 1**
