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

//--- Harmonic Pattern Types (Fibonacci-based structure patterns)
enum ENUM_HARMONIC_PATTERN
  {
   HARMONIC_NONE,
   HARMONIC_ABCD,
   HARMONIC_GARTLEY,
   HARMONIC_BAT,
   HARMONIC_ALT_BAT,
   HARMONIC_BUTTERFLY,
   HARMONIC_CRAB,
   HARMONIC_DEEP_CRAB,
   HARMONIC_THREE_DRIVES,
   HARMONIC_CYPHER,
   HARMONIC_SHARK,
   HARMONIC_FIVE_O,
   HARMONIC_NEN_STAR,
   HARMONIC_BLACK_SWAN,
   HARMONIC_WHITE_SWAN
  };

// ---
// --- SWING POINT STRUCTURE (for ZigZag)
// ---
struct SwingPoint
  {
   double            price;
   datetime          time;
   int               barIndex;
   bool              isHigh;    // true = swing high, false = swing low
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
   double             fastMA_3; // Fast MA value [shift 3]
   double             slowMA_3; // Slow MA value [shift 3]
   
   // --- v4.0 FIELDS: ZigZag & Harmonic Patterns ---
   double             lastSwingHigh;       // Most recent swing high price
   double             lastSwingLow;        // Most recent swing low price
   int                swingDirection;      // 1 = bullish (up), -1 = bearish (down)
   bool               hasHarmonicPattern;  // true if harmonic pattern detected
   ENUM_HARMONIC_PATTERN harmonicPattern;  // Type of harmonic pattern
   double             prz_high;            // Potential Reversal Zone - high
   double             prz_low;             // Potential Reversal Zone - low
   double             harmonicConfidence;  // Pattern quality score 0.0-1.0
   bool               harmonicIsBullish;   // true = bullish pattern, false = bearish
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
