//+------------------------------------------------------------------+
//|                                                 C_BiasEngine.mqh |
//|  Synthesizes all multi-timeframe data into a single, actionable  |
//|  trading bias. (Blueprint 2.3)                                   |
//+------------------------------------------------------------------+
#ifndef LULA_BIAS_ENGINE_MQH
#define LULA_BIAS_ENGINE_MQH

// We ONLY need the enums/structs file.
// DO NOT include C_MarketAnalyzer.mqh here.
#include "Lula_CoreEnums.mqh" 

// The BiasAnalysis struct is now in Lula_CoreEnums.mqh

class C_BiasEngine
  {
public:
   //--- Constructor
   C_BiasEngine(void) { }
   
   //--- Destructor
  ~C_BiasEngine(void) { }

   //--- Main analysis method
   //--- This will now compile, as TimeframeAnalysis is defined in Lula_CoreEnums.mqh
   BiasAnalysis DetermineBias(const TimeframeAnalysis &tfM15,
                              const TimeframeAnalysis &tfM30,
                              const TimeframeAnalysis &tfH1)
     {
      BiasAnalysis analysis;
      ZeroMemory(analysis);
      
      //---
      //--- RULE 1: V3 FRAMEWORK - HIGHER TIMEFRAME (H1) IS DOMINANT
      //---
      
      //--- STRONG BULLISH BIAS ---
      if(tfH1.trend == TREND_UP)
        {
         if(tfM30.trend == TREND_UP || tfM15.trend == TREND_UP)
           {
            analysis.bias = BIAS_BULLISH;
            analysis.confidence = 0.75; // Strong
            analysis.reasoning = "H1 trend is UP. LTF (M15/M30) confirms bullish momentum.";
            analysis.tf1hAgreement = true;
            analysis.tf30mAgreement = (tfM30.trend == TREND_UP);
            analysis.tf15mAgreement = (tfM15.trend == TREND_UP);
            return analysis;
           }
         if(tfM30.trend == TREND_SIDEWAYS && tfM15.trend == TREND_SIDEWAYS)
           {
            analysis.bias = BIAS_BULLISH;
            analysis.confidence = 0.5; // Moderate
            analysis.reasoning = "H1 trend is UP. LTF (M15/M30) are consolidating. Waiting for breakout.";
            analysis.tf1hAgreement = true;
            return analysis;
           }
        }

      //--- STRONG BEARISH BIAS ---
      if(tfH1.trend == TREND_DOWN)
        {
         if(tfM30.trend == TREND_DOWN || tfM15.trend == TREND_DOWN)
           {
            analysis.bias = BIAS_BEARISH;
            analysis.confidence = 0.75; // Strong
            analysis.reasoning = "H1 trend is DOWN. LTF (M15/M30) confirms bearish momentum.";
            analysis.tf1hAgreement = true;
            analysis.tf30mAgreement = (tfM30.trend == TREND_DOWN);
            analysis.tf15mAgreement = (tfM15.trend == TREND_DOWN);
            return analysis;
           }
         if(tfM30.trend == TREND_SIDEWAYS && tfM15.trend == TREND_SIDEWAYS)
           {
            analysis.bias = BIAS_BEARISH;
            analysis.confidence = 0.5; // Moderate
            analysis.reasoning = "H1 trend is DOWN. LTF (M15/M30) are consolidating. Waiting for breakdown.";
            analysis.tf1hAgreement = true;
            return analysis;
           }
        }
        
      //---
      //--- RULE 2: CONFLICTED OR NEUTRAL
      //---
      
      if(tfH1.trend == TREND_UP && (tfM30.trend == TREND_DOWN || tfM15.trend == TREND_DOWN))
        {
         analysis.bias = BIAS_CONFLICTED;
         analysis.confidence = 0.9;
         analysis.reasoning = "CONFLICT: H1 is UP, but LTF (M15/M30) is DOWN. No trade.";
         return analysis;
        }
        
      if(tfH1.trend == TREND_DOWN && (tfM30.trend == TREND_UP || tfM15.trend == TREND_UP))
        {
         analysis.bias = BIAS_CONFLICTED;
         analysis.confidence = 0.9;
         analysis.reasoning = "CONFLICT: H1 is DOWN, but LTF (M15/M30) is UP. No trade.";
         return analysis;
        }
        
      if(tfH1.trend == TREND_SIDEWAYS && tfM30.trend == TREND_SIDEWAYS && tfM15.trend == TREND_SIDEWAYS)
        {
         analysis.bias = BIAS_NEUTRAL;
         analysis.confidence = 0.75;
         analysis.reasoning = "NEUTRAL: All TFs are ranging. Waiting for H1 breakout.";
         return analysis;
        }

      // Default
      analysis.bias = BIAS_NEUTRAL;
      analysis.confidence = 0.5;
      analysis.reasoning = "NEUTRAL: Market is undecided. H1 is ranging or TFs are mixed.";
      return analysis;
     }
  };
//+------------------------------------------------------------------+
#endif // LULA_BIAS_ENGINE_MQH

