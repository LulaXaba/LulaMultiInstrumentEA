//+------------------------------------------------------------------+
//|                                          C_TimeframeAnalyzer.mqh |
//|            v4.0: Added ZigZag and Harmonic Pattern Detection      |
//+------------------------------------------------------------------+
#ifndef TIMEFRAME_ANALYZER_MQH
#define TIMEFRAME_ANALYZER_MQH

#include "Lula_CoreEnums.mqh"
#include "C_VolatilityAnalyzer.mqh"
#include "C_TrendDetector.mqh"
#include "C_SupportResistance.mqh"
#include "C_ZigZag.mqh"
#include "C_HarmonicRecognizer.mqh"
#include "../Instruments/C_InstrumentConfig.mqh"
#include "../Lula_PatternRecognizer.mqh"

//+------------------------------------------------------------------+
//| Class to handle analysis for a single timeframe                  |
//+------------------------------------------------------------------+
class C_TimeframeAnalyzer : public CObject
  {
private:
   ENUM_TIMEFRAMES      m_timeframe;
   string               m_symbol;
   C_InstrumentConfig*  m_config;

   //--- Analysis Modules
   C_VolatilityAnalyzer* m_volatility;
   C_TrendDetector*      m_trend;
   C_SupportResistance*  m_sr;
   CLulaPatternRecognizer* m_patternRecognizer;
   
   //--- v4.0: ZigZag and Harmonic Pattern Modules
   C_ZigZag*             m_zigzag;
   C_HarmonicRecognizer* m_harmonicRecognizer;

   //--- Results
   TimeframeAnalysis    m_results;

public:
   //--- Constructor
   C_TimeframeAnalyzer(void)
     {
      m_volatility = NULL;
      m_trend = NULL;
      m_sr = NULL;
      m_patternRecognizer = NULL;
      m_zigzag = NULL;
      m_harmonicRecognizer = NULL;
      m_timeframe = PERIOD_CURRENT;
     }

   //--- Destructor
   ~C_TimeframeAnalyzer(void)
     {
      if(CheckPointer(m_volatility) != POINTER_INVALID) delete m_volatility;
      if(CheckPointer(m_trend) != POINTER_INVALID) delete m_trend;
      if(CheckPointer(m_sr) != POINTER_INVALID) delete m_sr;
      if(CheckPointer(m_patternRecognizer) != POINTER_INVALID) delete m_patternRecognizer;
      if(CheckPointer(m_zigzag) != POINTER_INVALID) delete m_zigzag;
      if(CheckPointer(m_harmonicRecognizer) != POINTER_INVALID) delete m_harmonicRecognizer;
     }

   //--- Initialize
   bool Initialize(string symbol, ENUM_TIMEFRAMES timeframe, C_InstrumentConfig* config,
                  int fastLen, int fastSlow, int fastER, int slowLen, int slowSlow, int slowER)
     {
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_config = config;

      //--- Initialize Volatility Analyzer
      m_volatility = new C_VolatilityAnalyzer();
      if(!m_volatility.Initialize(m_symbol, m_timeframe, m_config)) 
         return false;

      //--- Initialize Trend Detector
      m_trend = new C_TrendDetector();
      if(!m_trend.Initialize(m_symbol, m_timeframe, fastLen, fastSlow, fastER, slowLen, slowSlow, slowER))
         return false;

      //--- Initialize Support & Resistance
      m_sr = new C_SupportResistance();
      if(!m_sr.Initialize(m_symbol, m_timeframe))
         return false;

      //--- Initialize Pattern Recognizer (Candlestick)
      m_patternRecognizer = new CLulaPatternRecognizer(0.0);

      //--- v4.0: Initialize ZigZag (depth in points based on volatility)
      m_zigzag = new C_ZigZag();
      int zigzagDepth = 100;  // Default depth, can be made configurable
      if(!m_zigzag.Initialize(m_symbol, m_timeframe, zigzagDepth))
         return false;

      //--- v4.0: Initialize Harmonic Recognizer
      m_harmonicRecognizer = new C_HarmonicRecognizer();
      if(!m_harmonicRecognizer.Initialize(0.01, 0.1))  // slackRange, slackUnary
         return false;

      return true;
     }

   //--- Run Analysis
   bool Analyze(void)
     {
      if(m_volatility == NULL || m_trend == NULL || m_sr == NULL) return false;

      //--- 1. Volatility
      m_results.volatilityPercent = m_volatility.CalculateVolatilityPercent();
      m_results.rawATR = m_volatility.GetRawATR();

      //--- 2. Trend
      if(m_trend.Calculate(300))
        {
         m_results.trend = m_trend.GetTrendDirection();
         m_results.trendStrength = m_trend.GetTrendStrength();
         
         m_results.fastMA_1 = m_trend.GetFastMAValue(1);
         m_results.fastMA_2 = m_trend.GetFastMAValue(2);
         m_results.slowMA_1 = m_trend.GetSlowMAValue(1);
         m_results.slowMA_2 = m_trend.GetSlowMAValue(2);
         m_results.fastMA_3 = m_trend.GetFastMAValue(3);
         m_results.slowMA_3 = m_trend.GetSlowMAValue(3);
        }
      else
        {
         m_results.trend = TREND_UNKNOWN;
         m_results.trendStrength = 0.0;
         m_results.fastMA_1 = 0.0;
         m_results.fastMA_2 = 0.0;
         m_results.slowMA_1 = 0.0;
         m_results.slowMA_2 = 0.0;
         m_results.fastMA_3 = 0.0;
         m_results.slowMA_3 = 0.0;
        }

      //--- 3. Support & Resistance
      m_sr.Analyze();
      m_results.nearestSupport = m_sr.GetNearestSupport();
      m_results.nearestResistance = m_sr.GetNearestResistance();

      //--- 4. Candlestick Pattern
      if(CheckPointer(m_patternRecognizer) != POINTER_INVALID)
        {
         MqlRates rates[];
         if(CopyRates(m_symbol, m_timeframe, 0, 5, rates) >= 5)
           {
            ArraySetAsSeries(rates, true);
            double open[5], high[5], low[5], close[5];
            for(int i = 0; i < 5; i++)
              {
               open[i]  = rates[i].open;
               high[i] = rates[i].high;
               low[i]  = rates[i].low;
               close[i] = rates[i].close;
              }
            m_results.pattern = m_patternRecognizer.CheckPatterns(1, open, high, low, close);
            m_results.hasPattern = (m_results.pattern != PATTERN_NONE);
           }
         else
           {
            m_results.pattern = PATTERN_NONE;
            m_results.hasPattern = false;
           }
        }

      //--- 5. v4.0: ZigZag Swing Analysis
      if(CheckPointer(m_zigzag) != POINTER_INVALID)
        {
         m_zigzag.Calculate(300);
         m_results.lastSwingHigh = m_zigzag.GetLastSwingHigh(0);
         m_results.lastSwingLow = m_zigzag.GetLastSwingLow(0);
         m_results.swingDirection = m_zigzag.GetCurrentDirection();
         
         //--- Debug: Log ZigZag swing info periodically (every H1 bar)
         if(m_timeframe == PERIOD_H1 && m_results.lastSwingHigh > 0)
           {
            Print(">>> ZigZag [H1]: SwingHigh=", m_results.lastSwingHigh, 
                  " SwingLow=", m_results.lastSwingLow, 
                  " Direction=", (m_results.swingDirection > 0 ? "BULLISH" : "BEARISH"),
                  " Swings=", m_zigzag.GetRecentSwingsCount());
           }
        }
      else
        {
         m_results.lastSwingHigh = 0;
         m_results.lastSwingLow = 0;
         m_results.swingDirection = 0;
        }

      //--- 6. v4.0: Harmonic Pattern Analysis
      m_results.hasHarmonicPattern = false;
      m_results.harmonicPattern = HARMONIC_NONE;
      m_results.prz_high = 0;
      m_results.prz_low = 0;
      m_results.harmonicConfidence = 0;
      m_results.harmonicIsBullish = false;
      
      if(CheckPointer(m_harmonicRecognizer) != POINTER_INVALID && 
         CheckPointer(m_zigzag) != POINTER_INVALID)
        {
         SwingPoint swings[];
         if(m_zigzag.GetRecentSwingPoints(swings, 5))
           {
            HarmonicPatternResult harmonicResult;
            ENUM_HARMONIC_PATTERN detected = m_harmonicRecognizer.CheckPatterns(swings, harmonicResult);
            
            if(detected != HARMONIC_NONE)
              {
               m_results.hasHarmonicPattern = true;
               m_results.harmonicPattern = detected;
               m_results.prz_high = harmonicResult.prz_high;
               m_results.prz_low = harmonicResult.prz_low;
               m_results.harmonicConfidence = harmonicResult.confidence;
               m_results.harmonicIsBullish = harmonicResult.isBullish;
               
               //--- Debug: Log harmonic pattern detection!
               Print(">>> *** HARMONIC PATTERN DETECTED [", EnumToString(m_timeframe), "] ***");
               Print("    Pattern: ", m_harmonicRecognizer.PatternToString(detected),
                     " | Direction: ", (harmonicResult.isBullish ? "BULLISH" : "BEARISH"),
                     " | Confidence: ", DoubleToString(harmonicResult.confidence * 100, 1), "%");
               Print("    PRZ Zone: ", harmonicResult.prz_low, " - ", harmonicResult.prz_high);
               Print("    X=", harmonicResult.X, " A=", harmonicResult.A, 
                     " B=", harmonicResult.B, " C=", harmonicResult.C, " D=", harmonicResult.D);
              }
           }
        }
      
      m_results.analysisTime = TimeCurrent();
      
      return true;
     }

   //--- Get Results
   TimeframeAnalysis GetResults(void) { return m_results; }
   
   //--- Get Timeframe
   ENUM_TIMEFRAMES GetTimeframe(void) { return m_timeframe; }
   
   //--- v4.0: Get ZigZag for external use
   C_ZigZag* GetZigZag(void) { return m_zigzag; }
   
   //--- v4.0: Get HarmonicRecognizer for external use
   C_HarmonicRecognizer* GetHarmonicRecognizer(void) { return m_harmonicRecognizer; }
  };

#endif // TIMEFRAME_ANALYZER_MQH
//+------------------------------------------------------------------+
