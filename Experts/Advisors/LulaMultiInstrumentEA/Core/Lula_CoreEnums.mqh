//+------------------------------------------------------------------+
//|                                               Lula_CoreEnums.mqh |
//|         Global Enumerations and Data Structures (Types)          |
//|------------------------------------------------------------------+
#ifndef LULA_CORE_ENUMS_MQH
#define LULA_CORE_ENUMS_MQH

//--- Include dependencies for the structs
#include "../Lula_PatternRecognizer.mqh" // For ENUM_SIGNAL_PATTERN

// ---
// --- ENUMERATIONS
// ---

//--- Defines the known categories of instruments
enum ENUM_INSTRUMENT_TYPE
  {
   TYPE_UNKNOWN,
   TYPE_VOLATILITY,
   TYPE_FOREX,
   TYPE_INDEX_MINI
  };

//--- Defines the trend state
enum ENUM_TREND_DIRECTION
  {
   TREND_UP,
   TREND_DOWN,
   TREND_SIDEWAYS,
   TREND_UNKNOWN
  };

//--- Defines the final consolidated bias
enum ENUM_BIAS
  {
   BIAS_BULLISH,
   BIAS_BEARISH,
   BIAS_NEUTRAL,
   BIAS_CONFLICTED
  };
  
// ---
// --- DATA STRUCTURES
// ---

//--- Blueprint 1.3: The data for a single timeframe
struct TimeframeAnalysis
  {
   ENUM_TIMEFRAMES    timeframe;
   ENUM_TREND_DIRECTION trend;
   double             trendStrength;
   bool               hasPattern;
   ENUM_SIGNAL_PATTERN pattern;
   double             volatilityPercent;
   double             rawATR; 
   datetime           analysisTime;
   double             nearestSupport;
   double             nearestResistance;
   
   // --- v3.2 FIELDS ---
   double             fastMA_1; // Fast MA value [shift 1]
   double             fastMA_2; // Fast MA value [shift 2]
   double             slowMA_1; // Slow MA value [shift 1]
   double             slowMA_2; // Slow MA value [shift 2]
  };

//--- Blueprint 2.3: The final consolidated bias output
struct BiasAnalysis
  {
   ENUM_BIAS          bias;
   double             confidence;
   string             reasoning;
   bool               tf15mAgreement;
   bool               tf30mAgreement;
   bool               tf1hAgreement;
  };

#endif // LULA_CORE_ENUMS_MQH
//+------------------------------------------------------------------+