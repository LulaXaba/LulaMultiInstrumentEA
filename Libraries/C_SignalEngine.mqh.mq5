//+------------------------------------------------------------------+
//|                                               C_SignalEngine.mqh |
//|          Handles all technical analysis and bias generation.     |
//+------------------------------------------------------------------+
#property strict

#include "Lula_PatternRecognizer.mqh" // Include our pattern recognizer

class C_SignalEngine
  {
private:
   CLulaPatternRecognizer *m_PatternRecognizer; // Instance of the pattern recognizer

public:
   //--- Constructor
   C_SignalEngine(void)
     {
      // Initialize with a default tolerance, can be adjusted via parameters
      m_PatternRecognizer = new CLulaPatternRecognizer(_Point / 2.0);
     }
   //--- Destructor
  ~C_SignalEngine(void)
     {
      if(CheckPointer(m_PatternRecognizer) != POINTER_INVALID)
         delete m_PatternRecognizer;
     }

   //--- Main method to check for entry signals
   ENUM_SIGNAL_PATTERN CheckEntrySignal(void)
     {
      // Rule 1: Trend Definition & HTF Agreement
      if(!IsTrendAligned())
         return(PATTERN_NONE);

      // Rule 2: Volatility/Consolidation Filters
      if(IsConsolidating())
         return(PATTERN_NONE);

      // Rule 3: Entry Location & Trigger (Candlestick Pattern)
      return(GetEntryTrigger());
     }

private:
   //--- Rule 1: Trend Definition
   bool IsTrendAligned(void)
     {
      // TODO: Implement logic to check Moving Averages, etc., on current and higher timeframes.
      // For now, we'll assume the trend is always aligned.
      return(true);
     }

   //--- Rule 2: Volatility Filter
   bool IsConsolidating(void)
     {
      // TODO: Implement ATR or Bollinger Band width check.
      // For now, we'll assume the market is never consolidating.
      return(false);
     }

   //--- Rule 3: Entry Trigger
   ENUM_SIGNAL_PATTERN GetEntryTrigger(void)
     {
      // TODO: Refine this logic, but it uses our existing pattern recognizer.
      MqlRates rates[];
      if(CopyRates(_Symbol, _Period, 0, 3, rates) < 3) return(PATTERN_NONE);
      ArraySetAsSeries(rates, true); // Newest bar is at index 0

      double open[3], high[3], low[3], close[3];
      for(int i = 0; i < 3; i++)
        {
         open[i]  = rates[2 - i].open;
         high[i]  = rates[2 - i].high;
         low[i]   = rates[2 - i].low;
         close[i] = rates[2 - i].close;
        }

      // Check the most recently completed bar (index 1 in our reversed array)
      return m_PatternRecognizer.CheckPatterns(1, open, high, low, close);
     }
  };