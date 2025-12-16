//+------------------------------------------------------------------+
//|                                          C_HarmonicStrategy.mqh |
//|       Strategy combining Harmonic Patterns + Candlestick Entry   |
//|                        v4.0 Integration                          |
//+------------------------------------------------------------------+
#ifndef LULA_HARMONIC_STRATEGY_MQH
#define LULA_HARMONIC_STRATEGY_MQH

#include "IStrategy.mqh"
#include "../C_BiasEngine.mqh"

//+------------------------------------------------------------------+
//| Harmonic Pattern Strategy                                         |
//| Entry Logic:                                                      |
//| 1. Detect completed harmonic pattern                              |
//| 2. Verify price is at PRZ (Potential Reversal Zone)               |
//| 3. Confirm with candlestick pattern                               |
//| 4. Validate with trend bias (optional confluence)                 |
//+------------------------------------------------------------------+
class C_HarmonicStrategy : public IStrategy
  {
private:
   C_MarketAnalyzer *m_marketAnalyzer;
   C_BiasEngine     *m_biasEngine;
   bool              m_requireBiasAlignment;  // If true, requires trend confirmation

public:
   //--- Constructor
   C_HarmonicStrategy(void)
     {
      m_marketAnalyzer = NULL;
      m_biasEngine = new C_BiasEngine();
      m_requireBiasAlignment = true;  // Default: require bias confirmation
     }

   //--- Destructor
   ~C_HarmonicStrategy(void)
     {
      if(CheckPointer(m_biasEngine) != POINTER_INVALID) delete m_biasEngine;
     }

   //--- Initialize
   virtual bool Initialize(C_MarketAnalyzer *marketAnalyzer)
     {
      if(marketAnalyzer == NULL) return false;
      m_marketAnalyzer = marketAnalyzer;
      return true;
     }

   //--- Get Strategy Name
   virtual string GetStrategyName(void) { return "Harmonic + Candlestick Strategy"; }

   //--- Set whether bias alignment is required
   void SetRequireBiasAlignment(bool require) { m_requireBiasAlignment = require; }

   //--- Check Entry Signal
   virtual ENUM_SIGNAL_PATTERN CheckEntrySignal(void)
     {
      if(m_marketAnalyzer == NULL || m_biasEngine == NULL) return PATTERN_NONE;

      //--- Get Analysis from Market Analyzer
      TimeframeAnalysis tfM15 = m_marketAnalyzer.GetAnalysis(PERIOD_M15);
      TimeframeAnalysis tfM30 = m_marketAnalyzer.GetAnalysis(PERIOD_M30);
      TimeframeAnalysis tfH1  = m_marketAnalyzer.GetAnalysis(PERIOD_H1);

      //--- Check for harmonic patterns on M15 and M30 (entry timeframes)
      //--- Priority: M15 first, then M30
      
      //--- Check M15 for harmonic + candlestick confluence
      if(tfM15.hasHarmonicPattern)
        {
         ENUM_SIGNAL_PATTERN signal = CheckHarmonicConfluence(tfM15, tfM30, tfH1);
         if(signal != PATTERN_NONE)
            return signal;
        }
      
      //--- Check M30 for harmonic + candlestick confluence
      if(tfM30.hasHarmonicPattern)
        {
         ENUM_SIGNAL_PATTERN signal = CheckHarmonicConfluence(tfM30, tfM15, tfH1);
         if(signal != PATTERN_NONE)
            return signal;
        }

      return PATTERN_NONE;
     }

private:
   //--- Check for harmonic pattern with candlestick confirmation
   ENUM_SIGNAL_PATTERN CheckHarmonicConfluence(const TimeframeAnalysis &primary,
                                                const TimeframeAnalysis &secondary,
                                                const TimeframeAnalysis &higher)
     {
      //--- Get current price
      double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      
      //--- Check if price is within the PRZ (Potential Reversal Zone)
      if(!IsPriceInPRZ(currentPrice, primary.prz_low, primary.prz_high))
         return PATTERN_NONE;
      
      //--- Determine if harmonic pattern is bullish or bearish
      bool isBullishHarmonic = primary.harmonicIsBullish;
      
      //--- If requiring bias alignment, check trend
      if(m_requireBiasAlignment)
        {
         BiasAnalysis bias = m_biasEngine.DetermineBias(secondary, primary, higher);
         
         if(isBullishHarmonic && bias.bias != BIAS_BULLISH)
            return PATTERN_NONE;
         if(!isBullishHarmonic && bias.bias != BIAS_BEARISH)
            return PATTERN_NONE;
        }
      
      //--- Look for confirming candlestick pattern
      if(isBullishHarmonic)
        {
         //--- Need bullish candlestick pattern at PRZ
         if(IsBullishPattern(primary.pattern))
            return primary.pattern;
         if(IsBullishPattern(secondary.pattern))
            return secondary.pattern;
        }
      else
        {
         //--- Need bearish candlestick pattern at PRZ
         if(IsBearishPattern(primary.pattern))
            return primary.pattern;
         if(IsBearishPattern(secondary.pattern))
            return secondary.pattern;
        }
      
      return PATTERN_NONE;
     }

   //--- Check if price is within PRZ
   bool IsPriceInPRZ(double price, double prz_low, double prz_high)
     {
      if(prz_low == 0 || prz_high == 0)
         return false;
      return (price >= prz_low && price <= prz_high);
     }

   //--- Helper: Check if pattern is bullish
   bool IsBullishPattern(ENUM_SIGNAL_PATTERN pattern)
     {
      return (pattern == PATTERN_BULL_ENGULF || 
              pattern == PATTERN_HAMMER || 
              pattern == PATTERN_BULL_HARAMI || 
              pattern == PATTERN_PIERCING || 
              pattern == PATTERN_MORNING_STAR);
     }

   //--- Helper: Check if pattern is bearish
   bool IsBearishPattern(ENUM_SIGNAL_PATTERN pattern)
     {
      return (pattern == PATTERN_BEAR_ENGULF || 
              pattern == PATTERN_SHOOTING_STAR || 
              pattern == PATTERN_BEAR_HARAMI || 
              pattern == PATTERN_DARK_CLOUD || 
              pattern == PATTERN_EVENING_STAR);
     }
  };

#endif // LULA_HARMONIC_STRATEGY_MQH
//+------------------------------------------------------------------+
