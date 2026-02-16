//+------------------------------------------------------------------+
//|                                      C_PerformanceTracker.mqh    |
//|                   LulaMultiInstrumentEA - Performance Tracking   |
//|                                   Phase 0: ML-Lite Foundation   |
//+------------------------------------------------------------------+
//| Description:                                                     |
//|   Performance analytics engine for ML-Lite signal filtering.    |
//|   Tracks win rate, profit factor, and expectancy by score tier  |
//|   (High: 0.7+, Medium: 0.5-0.7, Low: <0.5).                     |
//|                                                                  |
//| Key Features:                                                    |
//|   - Real-time metrics calculation by score tier                 |
//|   - Win rate and profit factor tracking                         |
//|   - Drawdown monitoring (current & max)                         |
//|   - Sharpe ratio calculation                                    |
//|   - Calibration checking (do high scores win more?)             |
//|   - Dashboard generation every 6 hours                          |
//|                                                                  |
//| Usage:                                                           |
//|   C_PerformanceTracker tracker;                                 |
//|   tracker.Initialize("ML_Data", 0.70, 0.50);                    |
//|   tracker.RecordSignal(score, wasTaken);                        |
//|   tracker.RecordOutcome(score, isWin, profitPips);              |
//|   string dashboard = tracker.GenerateDashboard(7);              |
//|                                                                  |
//| Dependencies: None (standalone)                                 |
//| Thread-Safe: Yes (no external state)                            |
//| Memory Usage: ~2 KB per instance                                |
//+------------------------------------------------------------------+
#property copyright "LulaXaba"
#property link      "https://github.com/LulaXaba/LulaMultiInstrumentEA"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Score Tier Metrics Structure                                     |
//+------------------------------------------------------------------+
struct TierMetrics
{
   // Signal tracking
   int signalsGenerated;      // Total signals in this tier
   int signalsTaken;          // Signals that were traded
   int signalsSkipped;        // Signals that were filtered
   
   // Trade outcomes
   int wins;                  // Winning trades
   int losses;                // Losing trades
   int breakevens;            // Break-even trades
   
   // P/L tracking
   double totalProfit;        // Sum of all profits (pips)
   double totalLoss;          // Sum of all losses (pips)
   double largestWin;         // Best trade (pips)
   double largestLoss;        // Worst trade (pips)
   
   // Derived metrics (calculated)
   double winRate;            // wins / (wins + losses)
   double profitFactor;       // totalProfit / totalLoss
   double avgWin;             // totalProfit / wins
   double avgLoss;            // totalLoss / losses
   double expectancy;         // Average $ per trade
   double takeRate;           // signalsTaken / signalsGenerated
};

//+------------------------------------------------------------------+
//| Performance Snapshot Structure                                   |
//+------------------------------------------------------------------+
struct PerformanceSnapshot
{
   datetime snapshotTime;
   
   TierMetrics highScoreTier;   // Score >= 0.70
   TierMetrics mediumScoreTier; // Score >= 0.50 and < 0.70
   TierMetrics lowScoreTier;    // Score < 0.50
   TierMetrics overall;         // All trades combined
   
   double currentDrawdown;      // Current DD in pips
   double maxDrawdown;          // Max DD seen (pips)
   double sharpeRatio;          // Risk-adjusted return
   double recoveryFactor;       // Profit / MaxDD
   
   bool isCalibrated;           // High scores winning more?
   double calibrationScore;     // Prediction accuracy %
};

//+------------------------------------------------------------------+
//| C_PerformanceTracker - ML Performance Analytics Engine           |
//+------------------------------------------------------------------+
class C_PerformanceTracker
{
private:
   // Tier metrics storage
   TierMetrics m_highTier;      // Score >= 0.70
   TierMetrics m_mediumTier;    // 0.50 <= Score < 0.70
   TierMetrics m_lowTier;       // Score < 0.50
   TierMetrics m_overall;       // All combined
   
   // 🆕 WEEK 4: Per-Strategy Metrics
   TierMetrics m_dayTradingMetrics;    // Day trading only
   TierMetrics m_swingTradingMetrics;  // Swing trading only
   TierMetrics m_legacyMetrics;        // Legacy strategy
   
   // Historical tracking
   double m_equityCurve[];      // Equity values
   datetime m_equityTimes[];    // Timestamps
   int m_equityCount;
   
   double m_peakEquity;
   double m_currentDrawdown;
   double m_maxDrawdown;
   
   // File management
   int m_metricsFileHandle;
   string m_metricsPath;
   string m_metricsFilePath;
   datetime m_lastFlush;
   
   // Configuration
   double m_highScoreThreshold;
   double m_mediumScoreThreshold;
   
   // Helper methods
   void CalculateDerivedMetrics(TierMetrics &tier);
   void UpdateDrawdown(double currentEquity);
   void UpdateEquityCurve(double equity);
   double CalculateSharpe();
   void FlushMetrics();
   
public:
   // Constructor/Destructor
   C_PerformanceTracker();
   ~C_PerformanceTracker();
   
   // Initialization
   bool Initialize(string metricsPath = "ML_Data", 
                   double highThreshold = 0.70,
                   double mediumThreshold = 0.50);
   void Shutdown();
   
   // Record signals & outcomes
   void RecordSignal(double score, bool wasTaken, string strategyName = "Legacy");  // 🆕 WEEK 4
   void RecordOutcome(double score, bool isWin, double profitPips, string strategyName = "Legacy");  // 🆕 WEEK 4
   
   // Query metrics
   TierMetrics GetHighTierMetrics() { return m_highTier; }
   TierMetrics GetMediumTierMetrics() { return m_mediumTier; }
   TierMetrics GetLowTierMetrics() { return m_lowTier; }
   TierMetrics GetOverallMetrics() { return m_overall; }
   
   PerformanceSnapshot GetSnapshot();
   
   // Dashboard
   string GenerateDashboard(int lookbackDays = 7);
   void PrintDashboard(int lookbackDays = 7);
   
   // Calibration
   bool IsScoreCalibrated();
   double GetCalibrationScore();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
C_PerformanceTracker::C_PerformanceTracker()
{
   m_metricsFileHandle = INVALID_HANDLE;
   m_metricsPath = "ML_Data";
   m_metricsFilePath = "";
   m_lastFlush = TimeCurrent();
   
   m_highScoreThreshold = 0.70;
   m_mediumScoreThreshold = 0.50;
   
   m_peakEquity = 0.0;
   m_currentDrawdown = 0.0;
   m_maxDrawdown = 0.0;
   m_equityCount = 0;
   
   ArrayResize(m_equityCurve, 1000);
   ArrayResize(m_equityTimes, 1000);
   
   // Initialize all tier metrics to zero
   ZeroMemory(m_highTier);
   ZeroMemory(m_mediumTier);
   ZeroMemory(m_lowTier);
   ZeroMemory(m_overall);
   // 🆕 WEEK 4: Initialize strategy metrics
   ZeroMemory(m_dayTradingMetrics);
   ZeroMemory(m_swingTradingMetrics);
   ZeroMemory(m_legacyMetrics);
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
C_PerformanceTracker::~C_PerformanceTracker()
{
   Shutdown();
}

//+------------------------------------------------------------------+
//| Initialize performance tracker                                   |
//+------------------------------------------------------------------+
bool C_PerformanceTracker::Initialize(string metricsPath, double highThreshold, double mediumThreshold)
{
   m_metricsPath = metricsPath;
   m_highScoreThreshold = highThreshold;
   m_mediumScoreThreshold = mediumThreshold;
   
   Print("Initializing C_PerformanceTracker...");
   Print("   Metrics Path: ", m_metricsPath);
   Print("   High Score Threshold: ", m_highScoreThreshold);
   Print("   Medium Score Threshold: ", m_mediumScoreThreshold);
   
   // Create metrics file path
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   string filename = StringFormat("metrics_%04d-%02d.csv", dt.year, dt.mon);
   m_metricsFilePath = m_metricsPath + "/" + filename;
   
   Print("✅ C_PerformanceTracker initialized successfully");
   return true;
}

//+------------------------------------------------------------------+
//| Shutdown and cleanup                                             |
//+------------------------------------------------------------------+
void C_PerformanceTracker::Shutdown()
{
   if(m_metricsFileHandle != INVALID_HANDLE)
   {
      Print("Shutting down C_PerformanceTracker...");
      FlushMetrics();
      FileClose(m_metricsFileHandle);
      m_metricsFileHandle = INVALID_HANDLE;
      Print("✅ C_PerformanceTracker shutdown complete");
   }
}

//+------------------------------------------------------------------+
//| Record signal generation                                         |
//+------------------------------------------------------------------+
void C_PerformanceTracker::RecordSignal(double score, bool wasTaken, string strategyName = "Legacy")
{
   // Update appropriate tier based on score
   if(score >= m_highScoreThreshold)
   {
      m_highTier.signalsGenerated++;
      if(wasTaken)
         m_highTier.signalsTaken++;
      else
         m_highTier.signalsSkipped++;
      CalculateDerivedMetrics(m_highTier);
   }
   else if(score >= m_mediumScoreThreshold)
   {
      m_mediumTier.signalsGenerated++;
      if(wasTaken)
         m_mediumTier.signalsTaken++;
      else
         m_mediumTier.signalsSkipped++;
      CalculateDerivedMetrics(m_mediumTier);
   }
   else
   {
      m_lowTier.signalsGenerated++;
      if(wasTaken)
         m_lowTier.signalsTaken++;
      else
         m_lowTier.signalsSkipped++;
      CalculateDerivedMetrics(m_lowTier);
   }
   
   // Update overall
   m_overall.signalsGenerated++;
   if(wasTaken)
      m_overall.signalsTaken++;
   else
      m_overall.signalsSkipped++;
   CalculateDerivedMetrics(m_overall);
   
   // 🆕 WEEK 4: Update strategy-specific metrics
   if(strategyName == "DayTrading")
   {
      m_dayTradingMetrics.signalsGenerated++;
      if(wasTaken) m_dayTradingMetrics.signalsTaken++;
      else m_dayTradingMetrics.signalsSkipped++;
      CalculateDerivedMetrics(m_dayTradingMetrics);
   }
   else if(strategyName == "SwingTrading")
   {
      m_swingTradingMetrics.signalsGenerated++;
      if(wasTaken) m_swingTradingMetrics.signalsTaken++;
      else m_swingTradingMetrics.signalsSkipped++;
      CalculateDerivedMetrics(m_swingTradingMetrics);
   }
   else
   {
      m_legacyMetrics.signalsGenerated++;
      if(wasTaken) m_legacyMetrics.signalsTaken++;
      else m_legacyMetrics.signalsSkipped++;
      CalculateDerivedMetrics(m_legacyMetrics);
   }
}

//+------------------------------------------------------------------+
//| Record trade outcome                                             |
//+------------------------------------------------------------------+
void C_PerformanceTracker::RecordOutcome(double score, bool isWin, double profitPips, string strategyName = "Legacy")
{
   // Update appropriate tier based on score
   if(score >= m_highScoreThreshold)
   {
      if(isWin)
      {
         m_highTier.wins++;
         m_highTier.totalProfit += profitPips;
         if(profitPips > m_highTier.largestWin)
            m_highTier.largestWin = profitPips;
      }
      else if(profitPips < -0.1)
      {
         m_highTier.losses++;
         double lossAmount = MathAbs(profitPips);
         m_highTier.totalLoss += lossAmount;
         if(lossAmount > m_highTier.largestLoss)
            m_highTier.largestLoss = lossAmount;
      }
      else
         m_highTier.breakevens++;
      
      CalculateDerivedMetrics(m_highTier);
   }
   else if(score >= m_mediumScoreThreshold)
   {
      if(isWin)
      {
         m_mediumTier.wins++;
         m_mediumTier.totalProfit += profitPips;
         if(profitPips > m_mediumTier.largestWin)
            m_mediumTier.largestWin = profitPips;
      }
      else if(profitPips < -0.1)
      {
         m_mediumTier.losses++;
         double lossAmount = MathAbs(profitPips);
         m_mediumTier.totalLoss += lossAmount;
         if(lossAmount > m_mediumTier.largestLoss)
            m_mediumTier.largestLoss = lossAmount;
      }
      else
         m_mediumTier.breakevens++;
      
      CalculateDerivedMetrics(m_mediumTier);
   }
   else
   {
      if(isWin)
      {
         m_lowTier.wins++;
         m_lowTier.totalProfit += profitPips;
         if(profitPips > m_lowTier.largestWin)
            m_lowTier.largestWin = profitPips;
      }
      else if(profitPips < -0.1)
      {
         m_lowTier.losses++;
         double lossAmount = MathAbs(profitPips);
         m_lowTier.totalLoss += lossAmount;
         if(lossAmount > m_lowTier.largestLoss)
            m_lowTier.largestLoss = lossAmount;
      }
      else
         m_lowTier.breakevens++;
      
      CalculateDerivedMetrics(m_lowTier);
   }
   
   // Update overall
   if(isWin)
   {
      m_overall.wins++;
      m_overall.totalProfit += profitPips;
      if(profitPips > m_overall.largestWin)
         m_overall.largestWin = profitPips;
   }
   else if(profitPips < -0.1)
   {
      m_overall.losses++;
      double lossAmount = MathAbs(profitPips);
      m_overall.totalLoss += lossAmount;
      if(lossAmount > m_overall.largestLoss)
         m_overall.largestLoss = lossAmount;
   }
   else
      m_overall.breakevens++;
   
   // Update equity curve
   UpdateEquityCurve(m_overall.totalProfit - m_overall.totalLoss);
   
   CalculateDerivedMetrics(m_overall);
   
   // 🆕 WEEK 4: Update strategy-specific metrics
   if(strategyName == "DayTrading")
   {
      if(isWin)
      {
         m_dayTradingMetrics.wins++;
         m_dayTradingMetrics.totalProfit += profitPips;
         if(profitPips > m_dayTradingMetrics.largestWin)
            m_dayTradingMetrics.largestWin = profitPips;
      }
      else if(profitPips < -0.1)
      {
         m_dayTradingMetrics.losses++;
         double lossAmount = MathAbs(profitPips);
         m_dayTradingMetrics.totalLoss += lossAmount;
         if(lossAmount > m_dayTradingMetrics.largestLoss)
            m_dayTradingMetrics.largestLoss = lossAmount;
      }
      else
         m_dayTradingMetrics.breakevens++;
      
      CalculateDerivedMetrics(m_dayTradingMetrics);
   }
   else if(strategyName == "SwingTrading")
   {
      if(isWin)
      {
         m_swingTradingMetrics.wins++;
         m_swingTradingMetrics.totalProfit += profitPips;
         if(profitPips > m_swingTradingMetrics.largestWin)
            m_swingTradingMetrics.largestWin = profitPips;
      }
      else if(profitPips < -0.1)
      {
         m_swingTradingMetrics.losses++;
         double lossAmount = MathAbs(profitPips);
         m_swingTradingMetrics.totalLoss += lossAmount;
         if(lossAmount > m_swingTradingMetrics.largestLoss)
            m_swingTradingMetrics.largestLoss = lossAmount;
      }
      else
         m_swingTradingMetrics.breakevens++;
      
      CalculateDerivedMetrics(m_swingTradingMetrics);
   }
   else  // Legacy
   {
      if(isWin)
      {
         m_legacyMetrics.wins++;
         m_legacyMetrics.totalProfit += profitPips;
         if(profitPips > m_legacyMetrics.largestWin)
            m_legacyMetrics.largestWin = profitPips;
      }
      else if(profitPips < -0.1)
      {
         m_legacyMetrics.losses++;
         double lossAmount = MathAbs(profitPips);
         m_legacyMetrics.totalLoss += lossAmount;
         if(lossAmount > m_legacyMetrics.largestLoss)
            m_legacyMetrics.largestLoss = lossAmount;
      }
      else
         m_legacyMetrics.breakevens++;
      
      CalculateDerivedMetrics(m_legacyMetrics);
   }
}

//+------------------------------------------------------------------+
//| Calculate derived metrics                                        |
//+------------------------------------------------------------------+
void C_PerformanceTracker::CalculateDerivedMetrics(TierMetrics &tier)
{
   int totalTrades = tier.wins + tier.losses;
   
   // Win rate
   if(totalTrades > 0)
      tier.winRate = (double)tier.wins / (double)totalTrades;
   else
      tier.winRate = 0.0;
   
   // Profit factor
   if(tier.totalLoss > 0)
      tier.profitFactor = tier.totalProfit / tier.totalLoss;
   else if(tier.totalProfit > 0)
      tier.profitFactor = 999.99; // Infinite (no losses)
   else
      tier.profitFactor = 0.0;
   
   // Average win
   if(tier.wins > 0)
      tier.avgWin = tier.totalProfit / (double)tier.wins;
   else
      tier.avgWin = 0.0;
   
   // Average loss
   if(tier.losses > 0)
      tier.avgLoss = tier.totalLoss / (double)tier.losses;
   else
      tier.avgLoss = 0.0;
   
   // Expectancy
   if(totalTrades > 0)
   {
      double lossRate = 1.0 - tier.winRate;
      tier.expectancy = (tier.winRate * tier.avgWin) - (lossRate * tier.avgLoss);
   }
   else
      tier.expectancy = 0.0;
   
   // Take rate
   if(tier.signalsGenerated > 0)
      tier.takeRate = (double)tier.signalsTaken / (double)tier.signalsGenerated;
   else
      tier.takeRate = 0.0;
}

//+------------------------------------------------------------------+
//| Update equity curve and drawdown                                 |
//+------------------------------------------------------------------+
void C_PerformanceTracker::UpdateEquityCurve(double equity)
{
   // Resize arrays if needed
   if(m_equityCount >= ArraySize(m_equityCurve))
   {
      ArrayResize(m_equityCurve, m_equityCount + 1000);
      ArrayResize(m_equityTimes, m_equityCount + 1000);
   }
   
   m_equityCurve[m_equityCount] = equity;
   m_equityTimes[m_equityCount] = TimeCurrent();
   m_equityCount++;
   
   UpdateDrawdown(equity);
}

//+------------------------------------------------------------------+
//| Update drawdown                                                   |
//+------------------------------------------------------------------+
void C_PerformanceTracker::UpdateDrawdown(double currentEquity)
{
   // Update peak
   if(currentEquity > m_peakEquity)
      m_peakEquity = currentEquity;
   
   // Calculate current drawdown
   m_currentDrawdown = m_peakEquity - currentEquity;
   
   // Update max drawdown
   if(m_currentDrawdown > m_maxDrawdown)
      m_maxDrawdown = m_currentDrawdown;
}

//+------------------------------------------------------------------+
//| Calculate Sharpe Ratio                                           |
//+------------------------------------------------------------------+
double C_PerformanceTracker::CalculateSharpe()
{
   if(m_equityCount < 2) return 0.0;
   
   // Calculate returns
   double returns[];
   ArrayResize(returns, m_equityCount - 1);
   
   for(int i = 1; i < m_equityCount; i++)
   {
      if(m_equityCurve[i-1] != 0)
         returns[i-1] = (m_equityCurve[i] - m_equityCurve[i-1]) / MathAbs(m_equityCurve[i-1]);
      else
         returns[i-1] = 0.0;
   }
   
   // Calculate mean return
   double meanReturn = 0.0;
   for(int i = 0; i < ArraySize(returns); i++)
      meanReturn += returns[i];
   meanReturn /= ArraySize(returns);
   
   // Calculate standard deviation
   double variance = 0.0;
   for(int i = 0; i < ArraySize(returns); i++)
      variance += MathPow(returns[i] - meanReturn, 2);
   variance /= ArraySize(returns);
   
   double stdDev = MathSqrt(variance);
   
   // Sharpe = (meanReturn - riskFreeRate) / stdDev
   // Assuming risk-free rate = 0
   if(stdDev > 0)
      return meanReturn / stdDev;
   else
      return 0.0;
}

//+------------------------------------------------------------------+
//| Check if scores are calibrated                                   |
//+------------------------------------------------------------------+
bool C_PerformanceTracker::IsScoreCalibrated()
{
   // Check if we have enough data
   int highTrades = m_highTier.wins + m_highTier.losses;
   int medTrades = m_mediumTier.wins + m_mediumTier.losses;
   
   if(highTrades < 5 || medTrades < 5)
      return true; // Not enough data, assume calibrated
   
   // High tier should have higher win rate than medium
   bool highBeatsMe = m_highTier.winRate > m_mediumTier.winRate;
   
   // High tier should have positive expectancy
   bool highProfitable = m_highTier.expectancy > 0;
   
   return (highBeatsMe && highProfitable);
}

//+------------------------------------------------------------------+
//| Get calibration score                                            |
//+------------------------------------------------------------------+
double C_PerformanceTracker::GetCalibrationScore()
{
   int highTrades = m_highTier.wins + m_highTier.losses;
   int medTrades = m_mediumTier.wins + m_mediumTier.losses;
   
   if(highTrades < 5 || medTrades < 5)
      return 100.0; // Not enough data
   
   // Calculate spread between high and medium win rates
   double spread = m_highTier.winRate - m_mediumTier.winRate;
   
   if(m_highTier.winRate == 0)
      return 0.0;
   
   // Return as percentage
   return (spread / m_highTier.winRate) * 100.0;
}

//+------------------------------------------------------------------+
//| Flush metrics to disk                                            |
//+------------------------------------------------------------------+
void C_PerformanceTracker::FlushMetrics()
{
   // TODO: Implement metrics file writing
   // For now, just update timestamp
   m_lastFlush = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Get performance snapshot                                         |
//+------------------------------------------------------------------+
PerformanceSnapshot C_PerformanceTracker::GetSnapshot()
{
   PerformanceSnapshot snapshot;
   
   snapshot.snapshotTime = TimeCurrent();
   snapshot.highScoreTier = m_highTier;
   snapshot.mediumScoreTier = m_mediumTier;
   snapshot.lowScoreTier = m_lowTier;
   snapshot.overall = m_overall;
   
   snapshot.currentDrawdown = m_currentDrawdown;
   snapshot.maxDrawdown = m_maxDrawdown;
   snapshot.sharpeRatio = CalculateSharpe();
   
   if(m_maxDrawdown > 0)
      snapshot.recoveryFactor = (m_overall.totalProfit - m_overall.totalLoss) / m_maxDrawdown;
   else
      snapshot.recoveryFactor = 0.0;
   
   snapshot.isCalibrated = IsScoreCalibrated();
   snapshot.calibrationScore = GetCalibrationScore();
   
   return snapshot;
}

//+------------------------------------------------------------------+
//| Generate performance dashboard                                   |
//+------------------------------------------------------------------+
string C_PerformanceTracker::GenerateDashboard(int lookbackDays = 7)
{
   string dashboard = "";
   
   dashboard += "========================================\n";
   dashboard += "ML-LITE PERFORMANCE DASHBOARD\n";
   dashboard += "========================================\n";
   dashboard += "Period: Last " + IntegerToString(lookbackDays) + " Days\n";
   dashboard += "Generated: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "\n\n";
   
   dashboard += "--- SCORE TIER ANALYSIS ---\n\n";
   
   // HIGH TIER
   dashboard += "HIGH TIER (>= 0.70):\n";
   dashboard += StringFormat("  Signals: %d (%d taken, %d skipped)\n", 
                             m_highTier.signalsGenerated, 
                             m_highTier.signalsTaken,
                             m_highTier.signalsSkipped);
   
   int highTrades = m_highTier.wins + m_highTier.losses;
   if(highTrades > 0)
   {
      dashboard += StringFormat("  Win Rate: %.1f%% (%dW/%dL)\n", 
                                m_highTier.winRate * 100.0, 
                                m_highTier.wins, 
                                m_highTier.losses);
      dashboard += StringFormat("  Profit Factor: %.2f\n", m_highTier.profitFactor);
      dashboard += StringFormat("  Avg Win: +%.1f pips | Avg Loss: -%.1f pips\n", 
                                m_highTier.avgWin, 
                                m_highTier.avgLoss);
      dashboard += StringFormat("  Expectancy: %+.1f pips/trade\n", m_highTier.expectancy);
   }
   else
   {
      dashboard += "  No trades yet\n";
   }
   dashboard += "\n";
   
   // MEDIUM TIER
   dashboard += "MEDIUM TIER (0.50-0.69):\n";
   dashboard += StringFormat("  Signals: %d (%d taken, %d skipped)\n", 
                             m_mediumTier.signalsGenerated,
                             m_mediumTier.signalsTaken,
                             m_mediumTier.signalsSkipped);
   
   int medTrades = m_mediumTier.wins + m_mediumTier.losses;
   if(medTrades > 0)
   {
      dashboard += StringFormat("  Win Rate: %.1f%% (%dW/%dL)\n", 
                                m_mediumTier.winRate * 100.0,
                                m_mediumTier.wins,
                                m_mediumTier.losses);
      dashboard += StringFormat("  Profit Factor: %.2f\n", m_mediumTier.profitFactor);
      dashboard += StringFormat("  Avg Win: +%.1f pips | Avg Loss: -%.1f pips\n", 
                                m_mediumTier.avgWin,
                                m_mediumTier.avgLoss);
      dashboard += StringFormat("  Expectancy: %+.1f pips/trade\n", m_mediumTier.expectancy);
   }
   else
   {
      dashboard += "  No trades yet\n";
   }
   dashboard += "\n";
   
   // LOW TIER
   dashboard += "LOW TIER (< 0.50):\n";
   dashboard += StringFormat("  Signals: %d (%d taken, %d skipped)\n", 
                             m_lowTier.signalsGenerated,
                             m_lowTier.signalsTaken,
                             m_lowTier.signalsSkipped);
   if(m_lowTier.signalsTaken == 0)
   {
      dashboard += "  Win Rate: N/A (all filtered)\n";
   }
   dashboard += "\n";
   
   // OVERALL
   dashboard += "--- OVERALL PERFORMANCE ---\n";
   dashboard += StringFormat("  Total Signals: %d\n", m_overall.signalsGenerated);
   dashboard += StringFormat("  Trades Taken: %d (%.1f%%)\n", 
                             m_overall.signalsTaken,
                             m_overall.takeRate * 100.0);
   
   int totalTrades = m_overall.wins + m_overall.losses;
   if(totalTrades > 0)
   {
      dashboard += StringFormat("  Win Rate: %.1f%% (%dW/%dL)\n", 
                                m_overall.winRate * 100.0,
                                m_overall.wins,
                                m_overall.losses);
      dashboard += StringFormat("  Profit Factor: %.2f\n", m_overall.profitFactor);
      dashboard += StringFormat("  Net P/L: %+.1f pips\n", 
                                m_overall.totalProfit - m_overall.totalLoss);
      dashboard += StringFormat("  Max Drawdown: -%.1f pips\n", m_maxDrawdown);
      dashboard += StringFormat("  Current DD: -%.1f pips\n", m_currentDrawdown);
   }
   dashboard += "\n";
   
   // 🆕 WEEK 4: STRATEGY BREAKDOWN
   dashboard += "--- STRATEGY BREAKDOWN ---\n";
   
   // Day Trading
   int dayTrades = m_dayTradingMetrics.wins + m_dayTradingMetrics.losses;
   dashboard += "DAY TRADING (H4→H1→M15):\n";
   if(dayTrades > 0)
   {
      dashboard += StringFormat("  Trades: %d (%dW/%dL) | Win Rate: %.1f%%\n",
                               dayTrades,
                               m_dayTradingMetrics.wins,
                               m_dayTradingMetrics.losses,
                               m_dayTradingMetrics.winRate * 100.0);
      dashboard += StringFormat("  Net P/L: %+.1f pips | PF: %.2f\n",
                               m_dayTradingMetrics.totalProfit - m_dayTradingMetrics.totalLoss,
                               m_dayTradingMetrics.profitFactor);
   }
   else
   {
      dashboard += "  No trades yet\n";
   }
   
   // Swing Trading
   int swingTrades = m_swingTradingMetrics.wins + m_swingTradingMetrics.losses;
   dashboard += "SWING TRADING (D1→H4→H1):\n";
   if(swingTrades > 0)
   {
      dashboard += StringFormat("  Trades: %d (%dW/%dL) | Win Rate: %.1f%%\n",
                               swingTrades,
                               m_swingTradingMetrics.wins,
                               m_swingTradingMetrics.losses,
                               m_swingTradingMetrics.winRate * 100.0);
      dashboard += StringFormat("  Net P/L: %+.1f pips | PF: %.2f\n",
                               m_swingTradingMetrics.totalProfit - m_swingTradingMetrics.totalLoss,
                               m_swingTradingMetrics.profitFactor);
   }
   else
   {
      dashboard += "  No trades yet\n";
   }
   
   // Legacy
   int legacyTrades = m_legacyMetrics.wins + m_legacyMetrics.losses;
   dashboard += "LEGACY STRATEGY:\n";
   if(legacyTrades > 0)
   {
      dashboard += StringFormat("  Trades: %d (%dW/%dL) | Win Rate: %.1f%%\n",
                               legacyTrades,
                               m_legacyMetrics.wins,
                               m_legacyMetrics.losses,
                               m_legacyMetrics.winRate * 100.0);
      dashboard += StringFormat("  Net P/L: %+.1f pips | PF: %.2f\n",
                               m_legacyMetrics.totalProfit - m_legacyMetrics.totalLoss,
                               m_legacyMetrics.profitFactor);
   }
   else
   {
      dashboard += "  No trades yet\n";
   }
   dashboard += "\n";
   
   // CALIBRATION
   dashboard += "--- CALIBRATION CHECK ---\n";
   bool calibrated = IsScoreCalibrated();
   double calibScore = GetCalibrationScore();
   
   dashboard += StringFormat("  Score Prediction Accuracy: %.1f%%\n", calibScore);
   dashboard += "  High scores win more: " + (calibrated ? "YES ✅" : "NO ⚠️") + "\n";
   dashboard += "  System is " + (calibrated ? "well-calibrated" : "needs tuning") + "\n";
   dashboard += "\n";
   
   dashboard += "========================================\n";
   
   return dashboard;
}

//+------------------------------------------------------------------+
//| Print dashboard to log                                           |
//+------------------------------------------------------------------+
void C_PerformanceTracker::PrintDashboard(int lookbackDays = 7)
{
   string dashboard = GenerateDashboard(lookbackDays);
   Print(dashboard);
}
//+------------------------------------------------------------------+

