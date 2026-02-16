//+------------------------------------------------------------------+
//|                                             LulaEA_Automated.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include "..\Core\Lula_CoreEnums.mqh"
#include "..\Core\C_MarketAnalyzer.mqh"
// FIXED PATH: C_InstrumentConfig is in Instruments folder
#include "..\Instruments\C_InstrumentConfig.mqh" 
#include "..\Execution\C_RiskManager.mqh"
#include "..\Execution\C_OrderManager.mqh"
#include "..\Execution\C_PositionSizer.mqh"
// ML Components
#include "..\Core\ML\C_DataCollector.mqh"
#include "..\Core\ML\C_SignalScorer.mqh"
#include "..\Core\ML\C_PerformanceTracker.mqh"
// 🆕 WEEK 4: Dual-Strategy System
#include "..\Core\Strategies\C_DayTradingStrategy.mqh"
#include "..\Core\Strategies\C_SwingTradingStrategy.mqh"

//--- Inputs
input double InpRiskPercent = 3.0;  // Aggressive Growth Mode
input double InpMaxDailyLoss = 5.0;
input int    InpFast_Length = 9;
input int    InpSlow_Length = 26;
input int    InpTrailStop = 50;           // Trailing Stop (pips) [SWING MODE]
input int    InpBreakEvenTrigger = 25;    // Break Even Trigger (pips)
input int    InpBreakEvenLock = 10;       // Break Even Lock (pips)
//--- ML Data Collection
input bool   InpMLDataCollection = true;  // Enable ML Data Collection
input string InpMLDataPath = "ML_Data";    // ML Data Directory
input int    InpMLMaxFileSize = 50;        // Max CSV File Size (MB)
input int    InpMLFlushInterval = 60;      // Data Flush Interval (minutes)
//--- ML-Lite Filtering
input bool   InpMLLiteEnabled = false;     // Enable ML-Lite Filtering
input double InpMLScoreThreshold = 0.60;   // Min Score to Take Trade (0.0-1.0)
input bool   InpMLRiskScaling = false;     // Scale Risk by Score
input double InpMLHighScoreMultiplier = 1.5;  // Risk Mult for Score >= 0.80
input double InpMLMediumScoreMultiplier = 1.2;// Risk Mult for Score >= 0.65
//--- 🆕 WEEK 4: Dual-Strategy Settings
input group "=== Dual Strategy Configuration ==="
input bool   InpEnableDayTrading = true;   // Enable Day Trading (H4→H1→M15)
input bool   InpEnableSwingTrading = true; // Enable Swing Trading (D1→H4→H1)
input double InpBaseRiskPercent = 3.0;     // Base Risk Per Symbol (%)
input ENUM_CONFLICT_MODE InpConflictMode = CONFLICT_SAME_DIRECTION_ONLY; // Conflict Resolution

//--- Global Objects
C_MarketAnalyzer m_market;
C_RiskManager    g_Risk;
C_OrderManager   g_Orders;
C_PositionSizer  m_positionSizer;
C_InstrumentConfig g_Config;
CPositionInfo    g_Position;
// ML Components
C_DataCollector  g_DataCollector;
C_SignalScorer   g_SignalScorer;
C_PerformanceTracker g_PerformanceTracker;
// 🆕 WEEK 4: Strategy Instances
C_DayTradingStrategy   g_DayStrategy;
C_SwingTradingStrategy g_SwingStrategy;

//+------------------------------------------------------------------+
//| Trade Tracking Structure for Outcome Logging                     |
//+------------------------------------------------------------------+
struct ActiveTrade
{
   string tradeId;        // Links to CSV signal (TradeID)
   ulong ticket;          // MT5 position ticket
   int direction;         // OP_BUY or OP_SELL
   double entryPrice;     // Actual entry price
   datetime entryTime;    // When position opened
   double initialSL;      // Original stop loss
   double initialTP;      // Original take profit
   double score;          // Signal score (for performance tracking)
};

ActiveTrade g_ActiveTrades[];  // Track all open positions for outcome logging

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //--- Initialize Config First
   if(!g_Config.Initialize(_Symbol)) return(INIT_FAILED);

   //--- Initialize Market Analyzer (Needs Symbol and Config Pointer)
   if(!m_market.Initialize(_Symbol, &g_Config)) return(INIT_FAILED);

   //--- FIX: Add Timeframes explicitly
   // Params: (Timeframe, FastLen, FastSlow, FastER, SlowLen, SlowSlow, SlowER)
   if(!m_market.AddTimeframe(PERIOD_H1, InpFast_Length, 0, 0, InpSlow_Length, 0, 0)) return(INIT_FAILED);
   if(!m_market.AddTimeframe(PERIOD_M15, InpFast_Length, 0, 0, InpSlow_Length, 0, 0)) return(INIT_FAILED);
   // 🆕 WEEK 4: Add D1 and H4 for dual-strategy system
   if(!m_market.AddTimeframe(PERIOD_D1, InpFast_Length, 0, 0, InpSlow_Length, 0, 0)) return(INIT_FAILED);
   if(!m_market.AddTimeframe(PERIOD_H4, InpFast_Length, 0, 0, InpSlow_Length, 0, 0)) return(INIT_FAILED);

   //--- Initialize Risk Manager (New Signature)
   g_Risk.Initialize(InpRiskPercent, InpMaxDailyLoss);

   //--- Initialize Order Manager (Needs Config Pointer)
   g_Orders.Initialize(&g_Config);
   
   //--- Initialize Position Sizer (Needs Config Pointer)
   if(!m_positionSizer.Initialize(&g_Config)) return(INIT_FAILED);

   //--- 🆕 WEEK 4: Initialize Dual-Strategy System
   if(InpEnableDayTrading)
     {
      if(!g_DayStrategy.Initialize(&m_market))
        {
         Print("ERROR: Day Trading Strategy initialization failed");
         return(INIT_FAILED);
        }
     }
   
   if(InpEnableSwingTrading)
     {
      if(!g_SwingStrategy.Initialize(&m_market))
        {
         Print("ERROR: Swing Trading Strategy initialization failed");
         return(INIT_FAILED);
        }
     }
   
   PrintFormat("✅ Dual-Strategy: Day=%s, Swing=%s, Conflict=%s",
              InpEnableDayTrading ? "ON" : "OFF",
              InpEnableSwingTrading ? "ON" : "OFF",
              EnumToString(InpConflictMode));

   //--- CRITICAL: Force initial calculation with sufficient history
   Print(">>> Warming up indicators...");
   if(!m_market.Analyze())
     {
      Print("ERROR: Initial market analysis failed!");
      return(INIT_FAILED);
     }
   
   Print(">>> LulaEA Initialized. Indicators ready.");
   
   //--- Initialize ML Components (if enabled)
   if(InpMLDataCollection)
     {
      // Initialize Signal Scorer
      if(!g_SignalScorer.Initialize())
        {
         Print("Warning: Signal Scorer initialization failed - ML disabled");
        }
      else
        {
         // Initialize Data Collector
         if(!g_DataCollector.Initialize(InpMLDataPath, InpMLMaxFileSize, InpMLFlushInterval))
           {
            Print("Warning: Data Collector initialization failed - ML disabled");
           }
         else
           {
            Print("? ML Data Collection enabled");
           }
        }
      
      // Initialize Performance Tracker if ML-Lite enabled
      if(InpMLLiteEnabled)
        {
         if(!g_PerformanceTracker.Initialize())
           {
            Print("Warning: Performance Tracker initialization failed - ML-Lite disabled");
           }
         else
           {
            Print("? ML-Lite Filtering enabled (Threshold: ", InpMLScoreThreshold, ")");
           }
        }
     }
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //--- Shutdown ML Components
   if(InpMLDataCollection)
     {
      g_DataCollector.Shutdown();
     }
   
   if(InpMLLiteEnabled)
     {
      // Print final dashboard
      Print("\n=== FINAL PERFORMANCE SUMMARY ===");
      g_PerformanceTracker.PrintDashboard(30); // 30-day summary
      g_PerformanceTracker.Shutdown();
     }
   
   Print("LulaEA Automated Deinitialized.");
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //--- 0. Manage Open Positions (Profit Protection)
   //--- FIX: Convert Pips to Points (Input 30 -> 300 Points)
   g_Orders.ManagePositions(InpTrailStop * 10, InpBreakEvenTrigger * 10, InpBreakEvenLock * 10);

   //--- 1. Update Market Analysis
   if(!m_market.Analyze()) return;

   //--- 1.5. Periodic ML Data Flush
   if(InpMLDataCollection)
     {
      g_DataCollector.PeriodicFlush();
     }
   
   //--- 1.6. Periodic Dashboard (every 6 hours)Yo
   static datetime lastDashboard = 0;
   if(InpMLLiteEnabled && (TimeCurrent() - lastDashboard) >= 21600)
     {
      Print("\n=== 6-HOUR PERFORMANCE UPDATE ===");
      g_PerformanceTracker.PrintDashboard(7);
      lastDashboard = TimeCurrent();
     }

   //--- 2. 🆕 WEEK 4: Check Both Strategies
   CheckDayTradingSignals();    // H4→H1→M15
   CheckSwingTradingSignals();  // D1→H4→H1
   
   //--- 3. Legacy Single-Strategy Check (keep for compatibility)
   CheckForNewTrade();
  }

//+------------------------------------------------------------------+
//| 🆕 WEEK 4: Dynamic Risk Allocation Helper Functions              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Get day trading risk based on active positions                   |
//+------------------------------------------------------------------+
double GetDayTradingRisk()
  {
   bool hasSwingPosition = HasActivePosition(STRATEGY_SWING_TRADING);
   
   if(hasSwingPosition)
      return InpBaseRiskPercent / 2.0;  // Split risk: 1.5% when swing active
   else
      return InpBaseRiskPercent;         // Full risk: 3% when solo
  }

//+------------------------------------------------------------------+
//| Get swing trading risk based on active positions                 |
//+------------------------------------------------------------------+
double GetSwingTradingRisk()
  {
   bool hasDayPosition = HasActivePosition(STRATEGY_DAY_TRADING);
   
   if(hasDayPosition)
      return InpBaseRiskPercent / 2.0;  // Split risk: 1.5% when day active
   else
      return InpBaseRiskPercent;         // Full risk: 3% when solo
  }

//+------------------------------------------------------------------+
//| Check if strategy has active position on current symbol          |
//+------------------------------------------------------------------+
bool HasActivePosition(ENUM_STRATEGY_TYPE strategyType)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(g_Position.SelectByIndex(i))
        {
         if(g_Position.Symbol() == _Symbol)
           {
            long magic = g_Position.Magic();
            
            // Check if magic number belongs to this strategy
            if(strategyType == STRATEGY_DAY_TRADING && magic >= 1000 && magic < 2000)
               return true;
            if(strategyType == STRATEGY_SWING_TRADING && magic >= 2000 && magic < 3000)
               return true;
           }
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Check if swing trend aligns with proposed day trade              |
//+------------------------------------------------------------------+
bool IsAlignedWithSwingTrend(int dayTradeDirection)
  {
   TimeframeAnalysis d1 = m_market.GetAnalysis(PERIOD_D1);
   
   if(dayTradeDirection == OP_BUY)
      return (d1.trend == TREND_UP || d1.trend == TREND_SIDEWAYS);
   else if(dayTradeDirection == OP_SELL)
      return (d1.trend == TREND_DOWN || d1.trend == TREND_SIDEWAYS);
   
   return true;  // Allow if unknown
  }

//+------------------------------------------------------------------+
//| 🆕 WEEK 4: Check Day Trading Signals (H4→H1→M15)                |
//+------------------------------------------------------------------+
void CheckDayTradingSignals()
  {
   if(!InpEnableDayTrading) return;
   if(HasActivePosition(STRATEGY_DAY_TRADING)) return;  // Already have day position
   
   // Check strategy for signal
   ENUM_SIGNAL_PATTERN pattern = g_DayStrategy.CheckEntrySignal();
   if(pattern == PATTERN_NONE) return;
   
   // Determine direction from pattern
   int direction = (pattern == PATTERN_BULL_ENGULF || pattern == PATTERN_HAMMER || 
                   pattern == PATTERN_BULL_HARAMI || pattern == PATTERN_PIERCING || 
                   pattern == PATTERN_MORNING_STAR) ? OP_BUY : OP_SELL;
   
   // Conflict Resolution
   if(InpConflictMode == CONFLICT_SAME_DIRECTION_ONLY)
     {
      if(!IsAlignedWithSwingTrend(direction))
        {
         PrintFormat("⚠️ Day trade blocked: Conflicts with D1 trend");
         return;
        }
     }
   
   // Dynamic risk allocation
   double riskPercent = GetDayTradingRisk();
   int magic = g_DayStrategy.GetMagicNumber(_Symbol);
   
   PrintFormat("📊 Day Trading %s: Pattern=%s, Risk=%.1f%%, Magic=%d",
              direction == OP_BUY ? "BUY" : "SELL",
              EnumToString(pattern),
              riskPercent,
              magic);
   
   // TODO: Execute trade with magic number
   // This will be expanded to call trade execution logic
  }

//+------------------------------------------------------------------+
//| 🆕 WEEK 4: Check Swing Trading Signals (D1→H4→H1)               |
//+------------------------------------------------------------------+
void CheckSwingTradingSignals()
  {
   if(!InpEnableSwingTrading) return;
   if(HasActivePosition(STRATEGY_SWING_TRADING)) return;  // Already have swing position
   
   // Check strategy for signal
   ENUM_SIGNAL_PATTERN pattern = g_SwingStrategy.CheckEntrySignal();
   if(pattern == PATTERN_NONE) return;
   
   // Determine direction from pattern
   int direction = (pattern == PATTERN_BULL_ENGULF || pattern == PATTERN_HAMMER || 
                   pattern == PATTERN_BULL_HARAMI || pattern == PATTERN_PIERCING || 
                   pattern == PATTERN_MORNING_STAR) ? OP_BUY : OP_SELL;
   
   // Swing trades take priority - block conflicting day trades if needed
   if(InpConflictMode == CONFLICT_SWING_PRIORITY && HasActivePosition(STRATEGY_DAY_TRADING))
     {
      TimeframeAnalysis d1 = m_market.GetAnalysis(PERIOD_D1);
      // Check if day position conflicts
      // This is informational only - swing can proceed
      PrintFormat("ℹ️ Swing trade while day position exists");
     }
   
   // Dynamic risk allocation
   double riskPercent = GetSwingTradingRisk();
   int magic = g_SwingStrategy.GetMagicNumber(_Symbol);
   
   PrintFormat("📊 Swing Trading %s: Pattern=%s, Risk=%.1f%%, Magic=%d",
              direction == OP_BUY ? "BUY" : "SELL",
              EnumToString(pattern),
              riskPercent,
              magic);
   
   // TODO: Execute trade with magic number
   // This will be expanded to call trade execution logic
  }

//+------------------------------------------------------------------+
//| Check for Trade Conditions                                       |
//+------------------------------------------------------------------+
void CheckForNewTrade()
  {
   //--- Cooldown Logic: Prevent Order Spam on Failure
   static datetime lastErrorTime = 0;
   if(TimeCurrent() - lastErrorTime < 60) return; // 1 Minute Cooldown

   //--- 0. Check if we already have a position
   if(g_Position.Select(_Symbol)) return;

   //--- 1. Get Analysis Results
   TimeframeAnalysis tfH1 = m_market.GetAnalysisH1();
   TimeframeAnalysis tfM15 = m_market.GetAnalysisM15();

   //--- Debug: Print H1 Trend Status periodically
   static datetime last_print = 0;
   bool isNewBar = (TimeCurrent() / 3600) != (last_print / 3600); // Hourly check
   
   if(isNewBar)
     {
      last_print = TimeCurrent();
      PrintFormat("DEBUG: H1 Trend=%d (Fast=%.5f, Slow=%.5f), M15 Fast1=%.5f, Slow1=%.5f, Fast2=%.5f, Slow2=%.5f", 
                  tfH1.trend, tfH1.fastMA_1, tfH1.slowMA_1, 
                  tfM15.fastMA_1, tfM15.slowMA_1, tfM15.fastMA_2, tfM15.slowMA_2);
     }
   
   //--- Details for Pullback Logic & Logs
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_M15, 1, 1, rates) < 1) return;
   
   double close1 = rates[0].close;
   double open1  = rates[0].open;
   double high1  = rates[0].high;
   double low1   = rates[0].low;
   
   //--- Calculations for Debugging & Signals
   double dist_fast_pips = (close1 - tfM15.fastMA_1) / _Point;
   double body_size_pips = MathAbs(close1 - open1) / _Point;

   //--- NEW: H1 Candle Momentum Filter
   MqlRates h1Rates[];
   ArraySetAsSeries(h1Rates, true);
   if(CopyRates(_Symbol, PERIOD_H1, 1, 1, h1Rates) < 1) return;
   
   double h1Close = h1Rates[0].close;
   double h1Open = h1Rates[0].open;
   bool h1IsBullish = (h1Close > h1Open);
   bool h1IsBearish = (h1Close < h1Open);

   //--- 4. Check for Trade Signals
   
   //--- FIX: Volatility Filter (Must be > 10 pips)
   if(tfH1.rawATR < 10 * _Point) return;
   if(tfM15.trendStrength > 0 && tfM15.trendStrength < 20) return; // M15 ADX check if avail

   //--- FIX: Session Time Filter (08:00 - 18:00 Only)
   MqlDateTime dt;
   TimeCurrent(dt);
   if(dt.hour < 8 || dt.hour >= 18) return; 

   //--- Common Confirmations
   // 🆕 WEEK 4: All 10 Nison Patterns Enabled (was 6)
   bool hasBullPattern = (tfM15.pattern == PATTERN_BULL_ENGULF || 
                          tfM15.pattern == PATTERN_HAMMER || 
                          tfM15.pattern == PATTERN_BULL_HARAMI ||     // ✅ NEW
                          tfM15.pattern == PATTERN_PIERCING ||        // ✅ NEW
                          tfM15.pattern == PATTERN_MORNING_STAR);
   
   bool hasBearPattern = (tfM15.pattern == PATTERN_BEAR_ENGULF || 
                          tfM15.pattern == PATTERN_SHOOTING_STAR || 
                          tfM15.pattern == PATTERN_BEAR_HARAMI ||     // ✅ NEW
                          tfM15.pattern == PATTERN_DARK_CLOUD ||      // ✅ NEW
                          tfM15.pattern == PATTERN_EVENING_STAR);

   if(tfH1.trend == TREND_UP && h1IsBullish)  // H1 Candle Momentum Filter
     {
      bool isAligned = (tfM15.fastMA_1 > tfM15.slowMA_1);
      
      //--- REFINED: Crossover Confirmation
      bool crossConfirmed = (tfM15.fastMA_1 > tfM15.slowMA_1) && (tfM15.fastMA_2 < tfM15.slowMA_2); // Fresh cross
      
      //--- REFINED: Pullback Logic
      // Price must dip close to FastMA (Dynamic Support) but close above it
      double maZone = 50 * _Point; // 5 pips tolerance
      bool touchedZone = (low1 <= tfM15.fastMA_1 + maZone); 
      bool rejectedZone = (close1 > tfM15.fastMA_1);
      bool bullishCandle = (close1 > open1);
      
      // Strict Pullback: Touched MA zone + Bullish Close + (Pattern Preferred)
      bool pullbackBuy = isAligned && touchedZone && rejectedZone && bullishCandle;
      
      if(isAligned)
        {
         if(crossConfirmed) PrintFormat(">>> DEBUG: M15 Buy Crossover. Pattern: %s", EnumToString(tfM15.pattern));
         if(pullbackBuy) PrintFormat(">>> DEBUG: M15 Buy Pullback. Low:%.5f MA:%.5f", low1, tfM15.fastMA_1);
        }

      //--- ENTRY TRIGGER (🆕 Enhanced with Pattern Strength)
      // 1. Fresh Crossover with Strong Pattern (Tier 1-2)
      // 2. Valid Pullback with Any Pattern (Tier 1-3)
      int patternStrength = GetPatternStrength(tfM15.pattern);
      
      if( (crossConfirmed && patternStrength >= 2) ||  // Crossover: Require Tier 1-2
          (pullbackBuy && patternStrength >= 1) )      // Pullback: Accept all tiers
        {
         string reason = crossConfirmed ? "Crossover+Pattern" : "Pullback";
         Print(">>> SIGNAL: BUY DETECTED! Reason: " + reason);
         
         //--- Step 1: Calculate Stop Loss and Take Profit
         double stopLoss = 0, takeProfit = 0;
         g_Risk.GetSmartSLTP(Symbol(), (int)TREND_UP, tfH1.rawATR, stopLoss, takeProfit);
         
         //--- Step 2: Calculate SL Distance
         double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double slPips = MathAbs(currentPrice - stopLoss) / _Point;
         
         //--- Step 3: Calculate Lot Size
         double lotSize = m_positionSizer.CalculateLotSize(InpRiskPercent, slPips);
         
         //--- ML: Score and Log Signal
         string tradeId = "";
         SignalScore score;
         
         if(InpMLDataCollection || InpMLLiteEnabled)
           {
            score = g_SignalScorer.EvaluateSignal(_Symbol, PERIOD_M15, OP_BUY, stopLoss, takeProfit);
            PrintFormat("ML: BUY Score=%.4f, Recommendation=%s", score.score, EnumToString(score.recommendation));
            
            // Record signal generation
            if(InpMLLiteEnabled)
              g_PerformanceTracker.RecordSignal(score.score, false); // Will update to true if taken
            
            // Log to CSV
            if(InpMLDataCollection)
              tradeId = g_DataCollector.LogSignal(score, _Symbol, PERIOD_M15, OP_BUY, currentPrice, stopLoss, takeProfit);
            
            // ML-Lite Filtering
            if(InpMLLiteEnabled && score.score < InpMLScoreThreshold)
              {
               PrintFormat(">>> SIGNAL FILTERED: Score %.4f < Threshold %.2f", score.score, InpMLScoreThreshold);
               return; // Skip this trade
              }
            
            // Risk Scaling
            if(InpMLLiteEnabled && InpMLRiskScaling)
              {
               if(score.score >= 0.80)
                 {
                  lotSize *= InpMLHighScoreMultiplier;
                  PrintFormat("   Risk scaled UP by %.1fx (High score)", InpMLHighScoreMultiplier);
                 }
               else if(score.score >= 0.65)
                 {
                  lotSize *= InpMLMediumScoreMultiplier;
                  PrintFormat("   Risk scaled UP by %.1fx (Medium score)", InpMLMediumScoreMultiplier);
                 }
              }
            
            // Update: Signal will be taken
            if(InpMLLiteEnabled)
              g_PerformanceTracker.RecordSignal(score.score, true);
           }
         
         PrintFormat(">>> EXECUTION: Placing BUY. Lot=%.2f, SL=%.5f, TP=%.5f", lotSize, stopLoss, takeProfit);
         
         if(lotSize > 0)
           {
            // Execute
            if(!g_Orders.ExecuteBuy(lotSize, stopLoss, takeProfit, "Lula Buy"))
              {
               lastErrorTime = TimeCurrent();
               Print(">>> ERROR: Trade Failed. Initiating 60s Cooldown.");
              }
           }
        }
     }
   else if(tfH1.trend == TREND_DOWN && h1IsBearish)  // H1 Candle Momentum Filter
     {
      bool isAligned = (tfM15.fastMA_1 < tfM15.slowMA_1);
      
      //--- REFINED: Crossover Confirmation
      bool crossConfirmed = (tfM15.fastMA_1 < tfM15.slowMA_1) && (tfM15.fastMA_2 > tfM15.slowMA_2); // Fresh cross
      
      //--- REFINED: Pullback Logic
      // Price must spike up to FastMA (Dynamic Resistance) but close below it
      double maZone = 50 * _Point; // 5 pips tolerance
      bool touchedZone = (high1 >= tfM15.fastMA_1 - maZone); 
      bool rejectedZone = (close1 < tfM15.fastMA_1);
      bool bearishCandle = (close1 < open1);
      
      // Strict Pullback: Touched MA zone + Bearish Close
      bool pullbackSell = isAligned && touchedZone && rejectedZone && bearishCandle;
      
      if(isAligned)
        {
         if(crossConfirmed) PrintFormat(">>> DEBUG: M15 Sell Crossover. Pattern: %s", EnumToString(tfM15.pattern));
         if(pullbackSell) PrintFormat(">>> DEBUG: M15 Sell Pullback. High:%.5f MA:%.5f", high1, tfM15.fastMA_1);
        }

      //--- ENTRY TRIGGER (🆕 Enhanced with Pattern Strength)
      // 1. Fresh Crossover with Strong Pattern (Tier 1-2)
      // 2. Valid Pullback with Any Pattern (Tier 1-3)
      int patternStrength = GetPatternStrength(tfM15.pattern);
      
      if( (crossConfirmed && patternStrength >= 2) ||  // Crossover: Require Tier 1-2
          (pullbackSell && patternStrength >= 1) )     // Pullback: Accept all tiers
        {
         string reason = crossConfirmed ? "Crossover+Pattern" : "Pullback";
         Print(">>> SIGNAL: SELL DETECTED! Reason: " + reason);
         
         //--- Step 1: Calculate Stop Loss and Take Profit
         double stopLoss = 0, takeProfit = 0;
         g_Risk.GetSmartSLTP(Symbol(), (int)TREND_DOWN, tfH1.rawATR, stopLoss, takeProfit);
         
         //--- Step 2: Calculate SL Distance
         double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double slPips = MathAbs(currentPrice - stopLoss) / _Point;

         //--- Step 3: Calculate Lot Size
         double lotSize = m_positionSizer.CalculateLotSize(InpRiskPercent, slPips);

         //--- ML: Score and Log Signal
         string tradeId = "";
         SignalScore score;
         
         if(InpMLDataCollection || InpMLLiteEnabled)
           {
            score = g_SignalScorer.EvaluateSignal(_Symbol, PERIOD_M15, OP_SELL, stopLoss, takeProfit);
            PrintFormat("ML: SELL Score=%.4f, Recommendation=%s", score.score, EnumToString(score.recommendation));
            
            // Record signal generation
            if(InpMLLiteEnabled)
              g_PerformanceTracker.RecordSignal(score.score, false);
            
            // Log to CSV
            if(InpMLDataCollection)
              tradeId = g_DataCollector.LogSignal(score, _Symbol, PERIOD_M15, OP_SELL, currentPrice, stopLoss, takeProfit);
            
            // ML-Lite Filtering
            if(InpMLLiteEnabled && score.score < InpMLScoreThreshold)
              {
               PrintFormat(">>> SIGNAL FILTERED: Score %.4f < Threshold %.2f", score.score, InpMLScoreThreshold);
               return;
              }
            
            // Risk Scaling
            if(InpMLLiteEnabled && InpMLRiskScaling)
              {
               if(score.score >= 0.80)
                 {
                  lotSize *= InpMLHighScoreMultiplier;
                  PrintFormat("   Risk scaled UP by %.1fx (High score)", InpMLHighScoreMultiplier);
                 }
               else if(score.score >= 0.65)
                 {
                  lotSize *= InpMLMediumScoreMultiplier;
                  PrintFormat("   Risk scaled UP by %.1fx (Medium score)", InpMLMediumScoreMultiplier);
                 }
              }
            
            // Update: Signal will be taken
            if(InpMLLiteEnabled)
              g_PerformanceTracker.RecordSignal(score.score, true);
           }

         PrintFormat(">>> EXECUTION: Placing SELL. Lot=%.2f, SL=%.5f, TP=%.5f", lotSize, stopLoss, takeProfit);
         
         if(lotSize > 0)
           {
            if(!g_Orders.ExecuteSell(lotSize, stopLoss, takeProfit, "Lula Sell"))
              {
               lastErrorTime = TimeCurrent();
               Print(">>> ERROR: Trade Failed. Initiating 60s Cooldown.");
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| 🆕 WEEK 4: Pattern Strength Scoring Function                     |
//| Returns pattern reliability tier (1-3, higher is stronger)        |
//+------------------------------------------------------------------+
int GetPatternStrength(ENUM_SIGNAL_PATTERN pattern)
  {
   // Tier 1 (Strongest): Engulfing patterns and Star patterns
   // High reliability, clear reversals, strong trend change signals
   if(pattern == PATTERN_BULL_ENGULF || pattern == PATTERN_BEAR_ENGULF ||
      pattern == PATTERN_MORNING_STAR || pattern == PATTERN_EVENING_STAR)
     {
      return 3;  // Highest confidence
     }
   
   // Tier 2 (Strong): Hammer, Shooting Star, Piercing, Dark Cloud
   // Good reliability, strong reversal signals, widely respected
   if(pattern == PATTERN_HAMMER || pattern == PATTERN_SHOOTING_STAR ||
      pattern == PATTERN_PIERCING || pattern == PATTERN_DARK_CLOUD)
     {
      return 2;  // High confidence
     }
   
   // Tier 3 (Moderate): Harami patterns
   // Moderate reliability, inside bar patterns, require confirmation
   if(pattern == PATTERN_BULL_HARAMI || pattern == PATTERN_BEAR_HARAMI)
     {
      return 1;  // Medium confidence
     }
   
   // No pattern detected
   return 0;
  }

//+------------------------------------------------------------------+
//| Helper Functions for Trade Outcome Tracking                      |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Store link between CSV TradeID and MT5 position ticket           |
//+------------------------------------------------------------------+
void StoreActiveTradeLink(string tradeId, ulong ticket, int direction, 
                         double entry, double sl, double tp, double signalScore)
{
   int size = ArraySize(g_ActiveTrades);
   ArrayResize(g_ActiveTrades, size + 1);
   
   g_ActiveTrades[size].tradeId = tradeId;
   g_ActiveTrades[size].ticket = ticket;
   g_ActiveTrades[size].direction = direction;
   g_ActiveTrades[size].entryPrice = entry;
   g_ActiveTrades[size].entryTime = TimeCurrent();
   g_ActiveTrades[size].initialSL = sl;
   g_ActiveTrades[size].initialTP = tp;
   g_ActiveTrades[size].score = signalScore;
   
   PrintFormat("?? Linked TradeID %s ? Ticket %I64u", tradeId, ticket);
}

//+------------------------------------------------------------------+
//| Remove trade from active tracking array                          |
//+------------------------------------------------------------------+
void RemoveActiveTradeByIndex(int index)
{
   int size = ArraySize(g_ActiveTrades);
   if(index < 0 || index >= size) return;
   
   // Shift remaining elements
   for(int i = index; i < size - 1; i++)
   {
      g_ActiveTrades[i] = g_ActiveTrades[i + 1];
   }
   
   ArrayResize(g_ActiveTrades, size - 1);
}

//+------------------------------------------------------------------+
//| Update MFE/MAE for all open positions                            |
//+------------------------------------------------------------------+
void UpdateMFE_MAE()
{
   for(int i = 0; i < ArraySize(g_ActiveTrades); i++)
   {
      if(PositionSelectByTicket(g_ActiveTrades[i].ticket))
      {
         double currentPrice =  PositionGetDouble(POSITION_PRICE_CURRENT);
         g_DataCollector.UpdateMFE_MAE(g_ActiveTrades[i].tradeId, 
                                       currentPrice, 
                                       g_ActiveTrades[i].direction);
      }
   }
}

//+------------------------------------------------------------------+
//| Check for closed positions and log outcomes                      |
//+------------------------------------------------------------------+
void CheckClosedPositions()
{
   // Select history for last 24 hours
   datetime fromTime = TimeCurrent() - 86400;
   HistorySelect(fromTime, TimeCurrent());
   
   // Check each active trade to see if it's still open
   for(int i = ArraySize(g_ActiveTrades) - 1; i >= 0; i--)
   {
      // Check if position still exists
      if(!PositionSelectByTicket(g_ActiveTrades[i].ticket))
      {
         // Position closed - log the outcome
         LogTradeOutcome(g_ActiveTrades[i]);
         
         // Remove from active trades array
         RemoveActiveTradeByIndex(i);
      }
   }
}

//+------------------------------------------------------------------+
//| Log trade outcome to CSV when position closes                    |
//+------------------------------------------------------------------+
void LogTradeOutcome(ActiveTrade &trade)
{
   TradeOutcome outcome;
   outcome.tradeId = trade.tradeId;
   outcome.executed = true;
   outcome.actualEntry = trade.entryPrice;
   outcome.entryTime = trade.entryTime;
   
   // Initialize defaults
   outcome.exitPrice = 0;
   outcome.exitTime = 0;
   outcome.profitCurrency = 0;
   outcome.profitPips = 0;
   outcome.outcome = "UNKNOWN";
   outcome.exitReason = "UNKNOWN";
   outcome.mfe = 0;
   outcome.mae = 0;
   
   // Find the closing deal in history
   int totalDeals = HistoryDealsTotal();
   bool foundExit = false;
   
   for(int i = totalDeals - 1; i >= 0; i--)
   {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket == 0) continue;
      
      ulong positionId = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
      long dealEntry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
      
      if(positionId == trade.ticket && dealEntry == DEAL_ENTRY_OUT)
      {
         // Found the exit deal
         outcome.exitPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
         outcome.exitTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
         outcome.profitCurrency = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
         
         // Calculate profit in pips
         double pipValue = _Point * 10; // Standard pip calculation
         if(trade.direction == OP_BUY)
            outcome.profitPips = (outcome.exitPrice - trade.entryPrice) / pipValue;
         else
            outcome.profitPips = (trade.entryPrice - outcome.exitPrice) / pipValue;
         
         // Determine outcome
         if(outcome.profitPips > 1.0)
            outcome.outcome = "WIN";
         else if(outcome.profitPips < -1.0)
            outcome.outcome = "LOSS";
         else
            outcome.outcome = "BREAKEVEN";
         
         // Determine exit reason
         double tolerance = _Point * 5; // 5 points tolerance
         if(MathAbs(outcome.exitPrice - trade.initialTP) < tolerance)
            outcome.exitReason = "TP";
         else if(MathAbs(outcome.exitPrice - trade.initialSL) < tolerance)
            outcome.exitReason = "SL";
         else
            outcome.exitReason = "MANUAL";
         
         foundExit = true;
         break;
      }
   }
   
   if(!foundExit)
   {
      Print("?? Warning: Could not find exit deal for ticket ", trade.ticket);
      outcome.outcome = "UNKNOWN";
      outcome.exitReason = "NOTFOUND";
   }
   
   // Log outcome to CSV
   bool success = g_DataCollector.LogOutcome(trade.tradeId, outcome);
   
   if(success)
   {
      PrintFormat("? Logged outcome: %s | %s | %.1f pips | $%.2f | %s", 
                  trade.tradeId, outcome.outcome, outcome.profitPips, 
                  outcome.profitCurrency, outcome.exitReason);
      
      // Update performance tracker if enabled
      if(InpMLLiteEnabled)
      {
         g_PerformanceTracker.RecordOutcome(trade.score, outcome.outcome == "WIN", outcome.profitPips);
      }
   }
   else
   {
      Print("? ERROR: Failed to log outcome for TradeID: ", trade.tradeId);
   }
}
