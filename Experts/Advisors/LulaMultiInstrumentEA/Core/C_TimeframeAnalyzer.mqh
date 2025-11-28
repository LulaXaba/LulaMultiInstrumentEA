//+------------------------------------------------------------------+
//|                                          C_TimeframeAnalyzer.mqh |
//+------------------------------------------------------------------+
#ifndef TIMEFRAME_ANALYZER_MQH
#define TIMEFRAME_ANALYZER_MQH

#include "Lula_CoreEnums.mqh"
#include "C_VolatilityAnalyzer.mqh"
#include "C_TrendDetector.mqh"
#include "C_SupportResistance.mqh"
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
      m_timeframe = PERIOD_CURRENT;
     }

   //--- Destructor
   ~C_TimeframeAnalyzer(void)
     {
      if(CheckPointer(m_volatility) != POINTER_INVALID) delete m_volatility;
      if(CheckPointer(m_trend) != POINTER_INVALID) delete m_trend;
      if(CheckPointer(m_sr) != POINTER_INVALID) delete m_sr;
      if(CheckPointer(m_patternRecognizer) != POINTER_INVALID) delete m_patternRecognizer;
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

      //--- Initialize Pattern Recognizer
      //--- Initialize Pattern Recognizer
      m_patternRecognizer = new CLulaPatternRecognizer(0.0);
      // No init needed for this class based on previous code

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
      // Ensure Calculate() is called before GetValue() with enough history
      if(m_trend.Calculate(300))
        {
         m_results.trend = m_trend.GetTrendDirection();
         m_results.trendStrength = m_trend.GetTrendStrength();
         
         m_results.fastMA_1 = m_trend.GetFastMAValue(1);
         m_results.fastMA_2 = m_trend.GetFastMAValue(2);
         m_results.slowMA_1 = m_trend.GetSlowMAValue(1);
         m_results.slowMA_2 = m_trend.GetSlowMAValue(2);
        }
      else
        {
         m_results.trend = TREND_UNKNOWN;
         m_results.trendStrength = 0.0;
         m_results.fastMA_1 = 0.0;
         m_results.fastMA_2 = 0.0;
         m_results.slowMA_1 = 0.0;
         m_results.slowMA_2 = 0.0;
        }

      //--- 3. Support & Resistance
      m_sr.Analyze();
      m_results.nearestSupport = m_sr.GetNearestSupport();
      m_results.nearestResistance = m_sr.GetNearestResistance();

      //--- 4. Pattern
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
      
      m_results.analysisTime = TimeCurrent();
      
      return true;
     }

   //--- Get Results
   TimeframeAnalysis GetResults(void) { return m_results; }
   
   //--- Get Timeframe
   ENUM_TIMEFRAMES GetTimeframe(void) { return m_timeframe; }
  };

#endif // TIMEFRAME_ANALYZER_MQH
