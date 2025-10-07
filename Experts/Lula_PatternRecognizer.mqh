//+------------------------------------------------------------------+
//|                                     Lula_PatternRecognizer.mqh |
//|                   Nison Tier 1 Candlestick Pattern Detection     |
//|------------------------------------------------------------------|
//| This class is designed to be included in the C_SignalEngine      |
//| module of the Expert Advisor, providing a clean signal (ENUM)    |
//| without indicator buffers or chart drawing.                      |
//+------------------------------------------------------------------+
#property strict

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
   // Tolerance for price comparisons (e.g., Point() or pip conversion)
   double            m_tolerance;

public:
   // Constructor: Initializes the comparison tolerance
   void              CLulaPatternRecognizer(const double tolerance)
     {
      m_tolerance = tolerance;
     }

   // Primary function to check for any defined pattern
   ENUM_SIGNAL_PATTERN CheckPatterns(const int index,
                                     const double &open[],
                                     const double &high[],
                                     const double &low[],
                                     const double &close[]);

private:
   // Utility function for safe floating-point price comparison
   int               CmpPrice(const double price1, const double price2)
     { return(MathAbs(price1 - price2) < m_tolerance ? 0 : (price1 > price2 ? 1 : -1)); }

   // --- CORE NISON PATTERN LOGIC FUNCTIONS (1-3 bars) ---

   // Bullish Pattern Functions
   bool              IsBullishEngulfing(const int index, const double &open[], const double &high[], const double &low[], const double &close[]);
   bool              IsHammer(const int index, const double &open[], const double &high[], const double &low[], const double &close[]);
   bool              IsBullishHarami(const int index, const double &open[], const double &high[], const double &low[], const double &close[]);
   bool              IsPiercingPattern(const int index, const double &open[], const double &high[], const double &low[], const double &close[]);

   // Bearish Pattern Functions
   bool              IsBearishEngulfing(const int index, const double &open[], const double &high[], const double &low[], const double &close[]);
   bool              IsShootingStar(const int index, const double &open[], const double &high[], const double &low[], const double &close[]);
   bool              IsBearishHarami(const int index, const double &open[], const double &high[], const double &low[], const double &close[]);
   bool              IsDarkCloudCover(const int index, const double &open[], const double &high[], const double &low[], const double &close[]);

   // 3-Bar Patterns
   bool              IsMorningStar(const int index, const double &open[], const double &high[], const double &low[], const double &close[]);
   bool              IsEveningStar(const int index, const double &open[], const double &high[], const double &low[], const double &close[]);

  };
//+------------------------------------------------------------------+
//| Primary Check Function: Returns the strongest signal found       |
//+------------------------------------------------------------------+
ENUM_SIGNAL_PATTERN CLulaPatternRecognizer::CheckPatterns(const int index,
                                                          const double &open[],
                                                          const double &high[],
                                                          const double &low[],
                                                          const double &close[])
  {
// Requires at least 2 bars for 2-bar patterns
   if(index >= 1)
     {
      if(IsBullishEngulfing(index, open, high, low, close)) return(PATTERN_BULL_ENGULF);
      if(IsBearishEngulfing(index, open, high, low, close)) return(PATTERN_BEAR_ENGULF);

      if(IsBullishHarami(index, open, high, low, close)) return(PATTERN_BULL_HARAMI);
      if(IsBearishHarami(index, open, high, low, close)) return(PATTERN_BEAR_HARAMI);

      if(IsPiercingPattern(index, open, high, low, close)) return(PATTERN_PIERCING);
      if(IsDarkCloudCover(index, open, high, low, close)) return(PATTERN_DARK_CLOUD);
     }

// Check 1-bar patterns (always available for index 0 or higher)
   if(IsHammer(index, open, high, low, close)) return(PATTERN_HAMMER);
   if(IsShootingStar(index, open, high, low, close)) return(PATTERN_SHOOTING_STAR);

// Check 3-bar patterns (requires index >= 2)
   if(index >= 2)
     {
      if(IsMorningStar(index, open, high, low, close)) return(PATTERN_MORNING_STAR);
      if(IsEveningStar(index, open, high, low, close)) return(PATTERN_EVENING_STAR);
     }

   return(PATTERN_NONE);
  }

//+------------------------------------------------------------------+
//| Candlestick Pattern Implementations                              |
//| FIX: All array access now uses the correct array variable names  |
//|      from the function signature.                                |
//+------------------------------------------------------------------+

// --- Bullish Patterns ---

bool CLulaPatternRecognizer::IsBullishEngulfing(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
  {
// Bar 1 (index+1) must be bearish
   if(CmpPrice(close[index + 1], open[index + 1]) >= 0) return(false);
// Bar 0 (index) must be bullish
   if(CmpPrice(close[index], open[index]) <= 0) return(false);
// Bar 0 body must completely engulf Bar 1 body
   if(CmpPrice(open[index], close[index + 1]) > 0) return(false); // Open 0 must be lower than Close 1
   if(CmpPrice(close[index], open[index + 1]) < 0) return(false); // Close 0 must be higher than Open 1
   return(true);
  }

bool CLulaPatternRecognizer::IsHammer(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
  {
   double body_size = MathAbs(open[index] - close[index]);
   double lower_shadow = fmin(open[index], close[index]) - low[index];
   double upper_shadow = high[index] - fmax(open[index], close[index]);

// Small body (any color, often at top of range)
   if(body_size * 2 >= lower_shadow) return(false);
// Long lower shadow (at least 2x body)
   if(CmpPrice(lower_shadow, body_size * 2) < 0) return(false);
// Small or no upper shadow (less than or equal to body size)
   if(CmpPrice(upper_shadow, body_size) > 0) return(false);
   return(true);
  }

bool CLulaPatternRecognizer::IsBullishHarami(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
  {
// Bar 1 (index+1) must be a large bearish candle (host)
   if(CmpPrice(close[index + 1], open[index + 1]) >= 0) return(false);
// Bar 0 (index) must be a small bullish candle (child)
   if(CmpPrice(close[index], open[index]) <= 0) return(false);
// Bar 0 must be contained within the body of Bar 1
   if(CmpPrice(high[index], open[index + 1]) > 0 || CmpPrice(low[index], close[index + 1]) < 0) return(false);
   return(true);
  }

bool CLulaPatternRecognizer::IsPiercingPattern(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
  {
// Bar 1 (index+1) must be bearish
   if(CmpPrice(close[index + 1], open[index + 1]) >= 0) return(false);
// Bar 0 (index) must be bullish
   if(CmpPrice(close[index], open[index]) <= 0) return(false);
// Bar 0 must open below the low of Bar 1 (a gap down)
   if(CmpPrice(open[index], low[index + 1]) >= 0) return(false);
// Bar 0 close must penetrate more than 50% into Bar 1's body
   double midpoint1 = (open[index + 1] + close[index + 1]) / 2.0;
   if(CmpPrice(close[index], midpoint1) <= 0) return(false);
// Bar 0 close must not exceed Bar 1 open
   if(CmpPrice(close[index], open[index + 1]) >= 0) return(false);
   return(true);
  }

// --- Bearish Patterns ---

bool CLulaPatternRecognizer::IsBearishEngulfing(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
  {
// Bar 1 (index+1) must be bullish
   if(CmpPrice(close[index + 1], open[index + 1]) <= 0) return(false);
// Bar 0 (index) must be bearish
   if(CmpPrice(close[index], open[index]) >= 0) return(false);
// Bar 0 body must completely engulf Bar 1 body
   if(CmpPrice(open[index], close[index + 1]) < 0) return(false); // Open 0 must be higher than Close 1
   if(CmpPrice(close[index], open[index + 1]) > 0) return(false); // Close 0 must be lower than Open 1
   return(true);
  }

bool CLulaPatternRecognizer::IsShootingStar(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
  {
   double body_size = MathAbs(open[index] - close[index]);
   double upper_shadow = high[index] - fmax(open[index], close[index]);
   double lower_shadow = fmin(open[index], close[index]) - low[index];

// Small body (any color, often at bottom of range)
   if(body_size * 2 >= upper_shadow) return(false);
// Long upper shadow (at least 2x body)
   if(CmpPrice(upper_shadow, body_size * 2) < 0) return(false);
// Small or no lower shadow (less than or equal to body size)
   if(CmpPrice(lower_shadow, body_size) > 0) return(false);
   return(true);
  }

bool CLulaPatternRecognizer::IsBearishHarami(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
  {
// Bar 1 (index+1) must be a large bullish candle (host)
   if(CmpPrice(close[index + 1], open[index + 1]) <= 0) return(false);
// Bar 0 (index) must be a small bearish candle (child)
   if(CmpPrice(close[index], open[index]) >= 0) return(false);
// Bar 0 must be contained within the body of Bar 1
   if(CmpPrice(high[index], close[index + 1]) > 0 || CmpPrice(low[index], open[index + 1]) < 0) return(false);
   return(true);
  }

bool CLulaPatternRecognizer::IsDarkCloudCover(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
  {
// Bar 1 (index+1) must be bullish
   if(CmpPrice(close[index + 1], open[index + 1]) <= 0) return(false);
// Bar 0 (index) must be bearish
   if(CmpPrice(close[index], open[index]) >= 0) return(false);
// Bar 0 must open above the high of Bar 1 (a gap up)
   if(CmpPrice(open[index], high[index + 1]) <= 0) return(false);
// Bar 0 close must penetrate more than 50% into Bar 1's body
   double midpoint1 = (open[index + 1] + close[index + 1]) / 2.0;
   if(CmpPrice(close[index], midpoint1) >= 0) return(false);
// Bar 0 close must not exceed Bar 1 open
   if(CmpPrice(close[index], open[index + 1]) <= 0) return(false);
   return(true);
  }

// --- 3-Bar Patterns ---

bool CLulaPatternRecognizer::IsMorningStar(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
  {
// 1. Bar 2 (index+2): Long bearish body (trend)
   if(CmpPrice(close[index + 2], open[index + 2]) >= 0) return(false);
// 2. Bar 1 (index+1): Small body (Star/Doji) that gaps below Bar 2's close
   if(CmpPrice(fmax(open[index+1],close[index+1]),close[index+2])>0)return(false);
// 3. Bar 0 (index): Long bullish body that closes deep into Bar 2's body
   if(CmpPrice(close[index], open[index]) <= 0) return(false);
   if(CmpPrice(close[index], (open[index + 2] + close[index + 2]) / 2.0) <= 0) return(false);
   return(true);
  }

bool CLulaPatternRecognizer::IsEveningStar(const int index, const double &open[], const double &high[], const double &low[], const double &close[])
  {
// 1. Bar 2 (index+2): Long bullish body (trend)
   if(CmpPrice(close[index + 2], open[index + 2]) <= 0) return(false);
// 2. Bar 1 (index+1): Small body (Star/Doji) that gaps above Bar 2's close
   if(CmpPrice(fmin(open[index+1],close[index+1]),close[index+2])<0)return(false);
// 3. Bar 0 (index): Long bearish body that closes deep into Bar 2's body
   if(CmpPrice(close[index], open[index]) >= 0) return(false);
   if(CmpPrice(close[index], (open[index + 2] + close[index + 2]) / 2.0) >= 0) return(false);
   return(true);
  }
//+------------------------------------------------------------------+