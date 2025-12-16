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

//--- Inputs
input double InpRiskPercent = 1.0;
input double InpMaxDailyLoss = 5.0;
input int    InpFast_Length = 9;
input int    InpSlow_Length = 26;

//--- Global Objects
C_MarketAnalyzer m_market;
C_RiskManager    g_Risk;
C_OrderManager   g_Orders;
C_PositionSizer  m_positionSizer;
C_InstrumentConfig g_Config;
CPositionInfo    g_Position;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //--- Initialize Config First
   if(!g_Config.Initialize(_Symbol)) return(INIT_FAILED);

   //--- Initialize Market Analyzer (Needs Symbol and Config Pointer)
   if(!m_market.Initialize(_Symbol, &g_Config)) return(INIT_FAILED);

   //--- FIX: Add Timeframes explicitly (H1 and M15)
   // Params: (Timeframe, FastLen, FastSlow, FastER, SlowLen, SlowSlow, SlowER)
   if(!m_market.AddTimeframe(PERIOD_H1, InpFast_Length, 0, 0, InpSlow_Length, 0, 0)) return(INIT_FAILED);
   if(!m_market.AddTimeframe(PERIOD_M15, InpFast_Length, 0, 0, InpSlow_Length, 0, 0)) return(INIT_FAILED);

   //--- Initialize Risk Manager (New Signature)
   g_Risk.Initialize(InpRiskPercent, InpMaxDailyLoss);

   //--- Initialize Order Manager (Needs Config Pointer)
   g_Orders.Initialize(&g_Config);
   
   //--- Initialize Position Sizer (Needs Config Pointer)
   if(!m_positionSizer.Initialize(&g_Config)) return(INIT_FAILED);

   //--- CRITICAL: Force initial calculation with sufficient history
   Print(">>> Warming up indicators...");
   if(!m_market.Analyze())
     {
      Print("ERROR: Initial market analysis failed!");
      return(INIT_FAILED);
     }
   
   Print(">>> LulaEA Initialized. Indicators ready.");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("LulaEA Automated Deinitialized.");
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //--- 1. Update Market Analysis
   if(!m_market.Analyze()) return;

   //--- 2. Check for New Trade
   CheckForNewTrade();
  }

//+------------------------------------------------------------------+
//| Check for Trade Conditions                                       |
//+------------------------------------------------------------------+
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


   //--- 4. Check for Trade Signals
   
   //--- FIX: Volatility Filter (Skip Dead Markets)
   if(tfH1.rawATR < 10 * _Point) return; // Min 10 pips volatility

   //--- FIX: Session Time Filter (08:00 - 18:00 Only)
   MqlDateTime dt;
   TimeCurrent(dt);
   if(dt.hour < 8 || dt.hour >= 18) return; // Skip Asian Session & Late NY

   if(tfH1.trend == TREND_UP)
     {
      bool isAligned = (tfM15.fastMA_1 > tfM15.slowMA_1);
      
      //--- FIX: 2-Bar Crossover Confirmation
      bool crossConfirmed = (tfM15.fastMA_1 > tfM15.slowMA_1) && (tfM15.fastMA_2 > tfM15.slowMA_2) && (tfM15.fastMA_3 < tfM15.slowMA_3);
      
      //--- FIX: Robust Pullback Validation
      double pullbackDepth = (tfM15.fastMA_1 - low1) / _Point;
      double candleRange = (high1 - low1);
      bool validDepth = (pullbackDepth >= 5.0 && pullbackDepth <= 30.0);
      bool priceAboveMA = (close1 > tfM15.fastMA_1 + (3 * _Point));
      bool strongBullish = (candleRange > 0) ? (body_size_pips * _Point / candleRange) > 0.5 : false;
      
      bool pullbackBuy = validDepth && priceAboveMA && strongBullish;
      
      if(isAligned)
        {
         if(crossConfirmed) PrintFormat(">>> DEBUG: M15 Buy Crossover Confirmed. Candle: %.1f pips", body_size_pips);
         if(pullbackBuy) PrintFormat(">>> DEBUG: M15 Buy Pullback. Low touched %.5f. Dist: %.1f pips.", tfM15.fastMA_1, dist_fast_pips);
        }

      //--- ENTRY TRIGER: Only Confirmed Crossover or Pullback
      if(isAligned && (crossConfirmed || pullbackBuy))
        {
         string reason = crossConfirmed ? "Crossover" : "Pullback";
         Print(">>> SIGNAL: BUY DETECTED! Reason: " + reason);
         
         //--- Step 1: Calculate Stop Loss and Take Profit (ATR Based)
         double stopLoss = 0, takeProfit = 0;
         g_Risk.GetSmartSLTP(Symbol(), (int)TREND_UP, tfH1.rawATR, stopLoss, takeProfit);
         
         //--- Step 2: Calculate SL Distance in Pips for Position Sizer
         double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double slPips = MathAbs(currentPrice - stopLoss) / _Point;
         
         //--- Step 3: Calculate Lot Size
         double lotSize = m_positionSizer.CalculateLotSize(InpRiskPercent, slPips);
         
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
   else if(tfH1.trend == TREND_DOWN)
     {
      bool isAligned = (tfM15.fastMA_1 < tfM15.slowMA_1);
      
      //--- FIX: 2-Bar Crossover Confirmation (Sell)
      bool crossConfirmed = (tfM15.fastMA_1 < tfM15.slowMA_1) && (tfM15.fastMA_2 < tfM15.slowMA_2) && (tfM15.fastMA_3 > tfM15.slowMA_3);
      
      //--- FIX: Robust Pullback Validation (Sell)
      double pullbackDepth = (high1 - tfM15.fastMA_1) / _Point;
      double candleRange = (high1 - low1);
      bool validDepth = (pullbackDepth >= 5.0 && pullbackDepth <= 30.0);
      bool priceBelowMA = (close1 < tfM15.fastMA_1 - (3 * _Point));
      bool strongBearish = (candleRange > 0) ? (body_size_pips * _Point / candleRange) > 0.5 : false;
      
      bool pullbackSell = validDepth && priceBelowMA && strongBearish;
      
      if(isAligned)
        {
         if(crossConfirmed) PrintFormat(">>> DEBUG: M15 Sell Crossover Confirmed. Candle: %.1f pips", body_size_pips);
         if(pullbackSell) PrintFormat(">>> DEBUG: M15 Sell Pullback. High touched %.5f. Dist: %.1f pips.", tfM15.fastMA_1, dist_fast_pips);
        }

      //--- ENTRY TRIGER: Only Confirmed Crossover or Pullback
      if(isAligned && (crossConfirmed || pullbackSell))
        {
         string reason = crossConfirmed ? "Crossover" : "Pullback";
         Print(">>> SIGNAL: SELL DETECTED! Reason: " + reason);
         
         //--- Step 1: Calculate Stop Loss and Take Profit
         double stopLoss = 0, takeProfit = 0;
         g_Risk.GetSmartSLTP(Symbol(), (int)TREND_DOWN, tfH1.rawATR, stopLoss, takeProfit);
         
         //--- Step 2: Calculate SL Distance in Pips
         double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double slPips = MathAbs(currentPrice - stopLoss) / _Point;

         //--- Step 3: Calculate Lot Size
         double lotSize = m_positionSizer.CalculateLotSize(InpRiskPercent, slPips);

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

