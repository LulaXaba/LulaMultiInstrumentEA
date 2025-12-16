//+------------------------------------------------------------------+
//|                                     Lula_PatternRecognizer.mqh   |
//|                   Nison Tier 1 Candlestick Pattern Detection     |
//|------------------------------------------------------------------|
#ifndef LULA_PATTERN_RECOGNIZER_MQH
#define LULA_PATTERN_RECOGNIZER_MQH

// #property strict <-- THIS LINE HAS BEEN REMOVED

//--- ENUMs for required Tier 1 Candlestick Signals
enum ENUM_SIGNAL_PATTERN
  {
   PATTERN_NONE,
   // Bullish Reversals
   PATTERN_BULL_ENGULF,
   PATTERN_HAMMER,
   PATTERN_BULL_HARAMI,
   PATTERN_PIERCING,
   PATTERN_MORNING_STAR,
   // Bearish Reversals
   PATTERN_BEAR_ENGULF,
   PATTERN_SHOOTING_STAR,
   PATTERN_BEAR_HARAMI,
   PATTERN_DARK_CLOUD,
   PATTERN_EVENING_STAR
  };

class CLulaPatternRecognizer
  {
private:
   double            m_tolerance;

public:
   //--- Constructor
   CLulaPatternRecognizer(const double tolerance) { m_tolerance = tolerance; }

   //--- Main pattern checking function
   ENUM_SIGNAL_PATTERN CheckPatterns(const int index,
                                     const double &open[],
                                     const double &high[],
                                     const double &low[],
                                     const double &close[])
     {
      // Check for patterns at the specified bar index
      if(IsBearishEngulfing(index, open, high, low, close)) return(PATTERN_BEAR_ENGULF);
      if(IsShootingStar(index, open, high, low, close)) return(PATTERN_SHOOTING_STAR);
      if(IsBearishHarami(index, open, high, low, close)) return(PATTERN_BEAR_HARAMI);
      if(IsDarkCloudCover(index, open, high, low, close)) return(PATTERN_DARK_CLOUD);
      if(IsEveningStar(index, open, high, low, close)) return(PATTERN_EVENING_STAR);

      if(IsBullishEngulfing(index, open, high, low, close)) return(PATTERN_BULL_ENGULF);
      if(IsHammer(index, open, high, low, close)) return(PATTERN_HAMMER);
      if(IsBullishHarami(index, open, high, low, close)) return(PATTERN_BULL_HARAMI);
      if(IsPiercingPattern(index, open, high, low, close)) return(PATTERN_PIERCING);
      if(IsMorningStar(index, open, high, low, close)) return(PATTERN_MORNING_STAR);

      return(PATTERN_NONE);
     }

   //--- Helper to compare prices with tolerance
   int CmpPrice(const double p1, const double p2)
     {
      if(p1 < p2 - m_tolerance) return -1;
      if(p1 > p2 + m_tolerance) return 1;
      return 0;
     }

   //--- Helper: Is the body bullish?
   bool IsBullishBody(const double open, const double close)
     {
      return(CmpPrice(close, open) > 0);
     }

   //--- Helper: Is the body bearish?
   bool IsBearishBody(const double open, const double close)
     {
      return(CmpPrice(close, open) < 0);
     }

   //--- Helper: Get body size
   double BodySize(const double open, const double close)
     {
      return(fabs(open - close));
     }

   //--- Helper: Get range
   double Range(const double high, const double low)
     {
      return(high - low);
     }

   //--- ========================================================== ---
   //--- PATTERN DEFINITIONS (Based on Nison)
   //--- ========================================================== ---

   bool IsBullishEngulfing(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
     {
      if(IsBullishBody(open[index + 1], close[index + 1])) return(false);
      if(IsBearishBody(open[index], close[index])) return(false);
      if(CmpPrice(close[index], open[index + 1]) >= 0 && CmpPrice(open[index], close[index + 1]) <= 0)
         return(true);
      return(false);
     }

   bool IsBearishEngulfing(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
     {
      if(IsBearishBody(open[index + 1], close[index + 1])) return(false);
      if(IsBullishBody(open[index], close[index])) return(false);
      if(CmpPrice(open[index], close[index + 1]) >= 0 && CmpPrice(close[index], open[index + 1]) <= 0)
         return(true);
      return(false);
     }

   bool IsHammer(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
     {
      double body = BodySize(open[index], close[index]);
      double range = Range(high[index], low[index]);
      if(range == 0) return(false); 
      
      double lower_wick = (IsBullishBody(open[index], close[index])) ? (open[index] - low[index]) : (close[index] - low[index]);
      double upper_wick = (IsBullishBody(open[index], close[index])) ? (high[index] - close[index]) : (high[index] - open[index]);

      if(CmpPrice(body, range * 0.33) < 0 && CmpPrice(lower_wick, body * 2.0) >= 0 && CmpPrice(upper_wick, body * 0.5) < 0)
         return(true);
      return(false);
     }

   bool IsShootingStar(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
     {
      double body = BodySize(open[index], close[index]);
      double range = Range(high[index], low[index]);
      if(range == 0) return(false);
      
      double lower_wick = (IsBullishBody(open[index], close[index])) ? (open[index] - low[index]) : (close[index] - low[index]);
      double upper_wick = (IsBullishBody(open[index], close[index])) ? (high[index] - close[index]) : (high[index] - open[index]);

      if(CmpPrice(body, range * 0.33) < 0 && CmpPrice(upper_wick, body * 2.0) >= 0 && CmpPrice(lower_wick, body * 0.5) < 0)
         return(true);
      return(false);
     }

   bool IsBullishHarami(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
     {
      if(IsBullishBody(open[index + 1], close[index + 1])) return(false);
      if(IsBearishBody(open[index], close[index])) return(false);
      if(CmpPrice(close[index], open[index + 1]) < 0 && CmpPrice(open[index], close[index + 1]) > 0)
         return(true);
      return(false);
     }

   bool IsBearishHarami(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
     {
      if(IsBearishBody(open[index + 1], close[index + 1])) return(false);
      if(IsBullishBody(open[index], close[index])) return(false);
      if(CmpPrice(open[index], close[index + 1]) < 0 && CmpPrice(close[index], open[index + 1]) > 0)
         return(true);
      return(false);
     }

   bool IsPiercingPattern(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
     {
      if(IsBullishBody(open[index + 1], close[index + 1])) return(false);
      if(IsBearishBody(open[index], close[index])) return(false);
      if(CmpPrice(open[index], low[index + 1]) >= 0) return(false);
      double prev_midpoint = (open[index + 1] + close[index + 1]) / 2.0;
      if(CmpPrice(close[index], prev_midpoint) > 0 && CmpPrice(close[index], open[index + 1]) < 0)
         return(true);
      return(false);
     }

   bool IsDarkCloudCover(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
     {
      if(IsBearishBody(open[index + 1], close[index + 1])) return(false);
      if(IsBullishBody(open[index], close[index])) return(false);
      if(CmpPrice(open[index], high[index + 1]) <= 0) return(false);
      double prev_midpoint = (open[index + 1] + close[index + 1]) / 2.0;
      if(CmpPrice(close[index], prev_midpoint) < 0 && CmpPrice(close[index], open[index + 1]) > 0)
         return(true);
      return(false);
     }

   bool IsMorningStar(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
     {
      if(IsBullishBody(open[index + 2], close[index + 2])) return(false);
      if(CmpPrice(fmax(open[index + 1], close[index + 1]), close[index + 2]) > 0) return(false);
      if(IsBearishBody(open[index], close[index])) return(false);
      if(CmpPrice(close[index], (open[index + 2] + close[index + 2]) / 2.0) <= 0) return(false);
      return(true);
     }

   bool IsEveningStar(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
     {
      if(IsBearishBody(open[index + 2], close[index + 2])) return(false);
      if(CmpPrice(fmin(open[index + 1], close[index + 1]), close[index + 2]) < 0) return(false);
      if(IsBullishBody(open[index], close[index])) return(false);
      if(CmpPrice(close[index], (open[index + 2] + close[index + 2]) / 2.0) >= 0) return(false);
      return(true);
     }
  };

#endif // LULA_PATTERN_RECOGNIZER_MQH
//+------------------------------------------------------------------+