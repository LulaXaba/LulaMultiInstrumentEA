//+------------------------------------------------------------------+
//|                                               C_LulaStrategy.mqh |
//|                      Implementation of the Lula Pattern Strategy |
//+------------------------------------------------------------------+
#ifndef LULA_STRATEGY_MQH
#define LULA_STRATEGY_MQH

#include "IStrategy.mqh"
#include "../C_BiasEngine.mqh"

class C_LulaStrategy : public IStrategy
  {
private:
   C_MarketAnalyzer *m_marketAnalyzer;
   C_BiasEngine     *m_biasEngine;

public:
   //--- Constructor
   C_LulaStrategy(void)
     {
      m_marketAnalyzer = NULL;
      m_biasEngine = new C_BiasEngine();
     }

   //--- Destructor
   ~C_LulaStrategy(void)
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
   virtual string GetStrategyName(void) { return "Lula Pattern Strategy"; }

   //--- Check Entry Signal
   virtual ENUM_SIGNAL_PATTERN CheckEntrySignal(void)
     {
      if(m_marketAnalyzer == NULL || m_biasEngine == NULL) return PATTERN_NONE;

   //--- Check for Entry Signal
   virtual ENUM_SIGNAL_PATTERN CheckEntrySignal(void)
     {
      if(m_marketAnalyzer == NULL || m_biasEngine == NULL) return PATTERN_NONE;

      // 1. Get Analysis from Market Analyzer
      TimeframeAnalysis tfM15; tfM15 = m_marketAnalyzer.GetAnalysis(PERIOD_M15);
      TimeframeAnalysis tfM30; tfM30 = m_marketAnalyzer.GetAnalysis(PERIOD_M30);
      TimeframeAnalysis tfH1;  tfH1  = m_marketAnalyzer.GetAnalysis(PERIOD_H1);

      // 2. Determine Bias
      BiasAnalysis bias = m_biasEngine.CalculateBias(tfM15, tfM30, tfH1);

      // 3. Look for Patterns matching the Bias
      // If Bullish Bias, look for Bullish Patterns on M15/M30
      if(bias.bias == BIAS_BULLISH)
        {
         if(IsBullishPattern(tfM15.pattern)) return tfM15.pattern;
         if(IsBullishPattern(tfM30.pattern)) return tfM30.pattern;
        }
      // If Bearish Bias, look for Bearish Patterns on M15/M30
      else if(bias.bias == BIAS_BEARISH)
        {
         if(IsBearishPattern(tfM15.pattern)) return tfM15.pattern;
         if(IsBearishPattern(tfM30.pattern)) return tfM30.pattern;
        }

      return PATTERN_NONE;
     }

private:
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

#endif // LULA_STRATEGY_MQH
