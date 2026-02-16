//+------------------------------------------------------------------+
//|                                     C_SwingTradingStrategy.mqh   |
//|                   Swing Trading Strategy: D1 → H4 → H1           |
//|                         Multi-Day Trend Following                 |
//+------------------------------------------------------------------+
#ifndef C_SWING_TRADING_STRATEGY_MQH
#define C_SWING_TRADING_STRATEGY_MQH

#include "../Strategies/IStrategy.mqh"
#include "../C_MarketAnalyzer.mqh"
#include "../Lula_CoreEnums.mqh"

//+------------------------------------------------------------------+
//| Swing Trading Strategy Class                                      |
//| Timeframes: D1 (trend) → H4 (confirmation) → H1 (execution)       |
//| Target: 4-8 trades/month per symbol, 70-75% win rate             |
//+------------------------------------------------------------------+
class C_SwingTradingStrategy : public IStrategy
  {
private:
   ENUM_TIMEFRAMES    m_primaryTF;      // D1 - Primary trend
   ENUM_TIMEFRAMES    m_secondaryTF;    // H4 - Confirmation
   ENUM_TIMEFRAMES    m_executionTF;    // H1 - Entry trigger
   C_MarketAnalyzer  *m_market;         // Market data provider

public:
   //+------------------------------------------------------------------+
   //| Constructor                                                       |
   //+------------------------------------------------------------------+
   C_SwingTradingStrategy(void)
     {
      m_primaryTF = PERIOD_D1;
      m_secondaryTF = PERIOD_H4;
      m_executionTF = PERIOD_H1;
      m_market = NULL;
     }
   
   //+------------------------------------------------------------------+
   //| Destructor                                                        |
   //+------------------------------------------------------------------+
   ~C_SwingTradingStrategy(void)
     {
      // Market analyzer is managed externally, don't delete
     }
   
   //+------------------------------------------------------------------+
   //| Initialize with market analyzer                                  |
   //+------------------------------------------------------------------+
   virtual bool Initialize(C_MarketAnalyzer *marketAnalyzer)
     {
      if(marketAnalyzer == NULL)
        {
         Print("ERROR: SwingTradingStrategy - NULL market analyzer");
         return false;
        }
      
      m_market = marketAnalyzer;
      PrintFormat("✅ Swing Trading Strategy initialized (D1→H4→H1)");
      return true;
     }
   
   //+------------------------------------------------------------------+
   //| Check for entry signal using triple-timeframe confirmation       |
   //+------------------------------------------------------------------+
   virtual ENUM_SIGNAL_PATTERN CheckEntrySignal(void)
     {
      if(m_market == NULL)
        {
         return PATTERN_NONE;
        }
      
      // Get all 3 timeframe analyses
      TimeframeAnalysis d1  = m_market.GetAnalysis(PERIOD_D1);
      TimeframeAnalysis h4  = m_market.GetAnalysis(PERIOD_H4);
      TimeframeAnalysis h1  = m_market.GetAnalysis(PERIOD_H1);
      
      // RULE 1: D1 must show clear directional trend (not sideways)
      if(d1.trend == TREND_SIDEWAYS || d1.trend == TREND_UNKNOWN)
        {
         return PATTERN_NONE;
        }
      
      // RULE 2: H4 must align with D1 trend
      if(d1.trend != h4.trend)
        {
         return PATTERN_NONE;
        }
      
      // RULE 3: H1 pattern must align with D1/H4 trend direction
      if(d1.trend == TREND_UP)
        {
         // Look for bullish patterns on H1
         if(IsBullishPattern(h1.pattern))
           {
            PrintFormat("📊 SwingTrading BUY: D1=%s, H4=%s, H1 Pattern=%s", 
                       EnumToString(d1.trend), 
                       EnumToString(h4.trend),
                       EnumToString(h1.pattern));
            return h1.pattern;
           }
        }
      else if(d1.trend == TREND_DOWN)
        {
         // Look for bearish patterns on H1
         if(IsBearishPattern(h1.pattern))
           {
            PrintFormat("📊 SwingTrading SELL: D1=%s, H4=%s, H1 Pattern=%s", 
                       EnumToString(d1.trend), 
                       EnumToString(h4.trend),
                       EnumToString(h1.pattern));
            return h1.pattern;
           }
        }
      
      return PATTERN_NONE;
     }
   
   //+------------------------------------------------------------------+
   //| Get strategy name                                                |
   //+------------------------------------------------------------------+
   virtual string GetStrategyName(void)
     {
      return "SwingTrading";
     }
   
   //+------------------------------------------------------------------+
   //| Get magic number for this strategy and symbol                    |
   //| Format: 2XXX where XXX is symbol code                           |
   //+------------------------------------------------------------------+
   int GetMagicNumber(string symbol)
     {
      int symbolCode = GetSymbolCode(symbol);
      return STRATEGY_SWING_TRADING + symbolCode;  // 2000 + code
     }
   
   //+------------------------------------------------------------------+
   //| Get primary timeframe (D1)                                       |
   //+------------------------------------------------------------------+
   ENUM_TIMEFRAMES GetPrimaryTimeframe(void)
     {
      return m_primaryTF;
     }
   
   //+------------------------------------------------------------------+
   //| Get execution timeframe (H1)                                     |
   //+------------------------------------------------------------------+
   ENUM_TIMEFRAMES GetExecutionTimeframe(void)
     {
      return m_executionTF;
     }

private:
   //+------------------------------------------------------------------+
   //| Check if pattern is bullish                                      |
   //+------------------------------------------------------------------+
   bool IsBullishPattern(ENUM_SIGNAL_PATTERN pattern)
     {
      return (pattern == PATTERN_BULL_ENGULF || 
              pattern == PATTERN_HAMMER || 
              pattern == PATTERN_BULL_HARAMI ||
              pattern == PATTERN_PIERCING ||
              pattern == PATTERN_MORNING_STAR);
     }
   
   //+------------------------------------------------------------------+
   //| Check if pattern is bearish                                      |
   //+------------------------------------------------------------------+
   bool IsBearishPattern(ENUM_SIGNAL_PATTERN pattern)
     {
      return (pattern == PATTERN_BEAR_ENGULF || 
              pattern == PATTERN_SHOOTING_STAR || 
              pattern == PATTERN_BEAR_HARAMI ||
              pattern == PATTERN_DARK_CLOUD ||
              pattern == PATTERN_EVENING_STAR);
     }
   
   //+------------------------------------------------------------------+
   //| Convert symbol to unique code for magic number                   |
   //| Same codes as Day Trading for consistency                        |
   //+------------------------------------------------------------------+
   int GetSymbolCode(string symbol)
     {
      // Forex pairs
      if(symbol == "EURUSD") return 1;
      if(symbol == "GBPUSD") return 2;
      if(symbol == "USDJPY") return 3;
      if(symbol == "AUDUSD") return 4;
      if(symbol == "EURGBP") return 8;
      if(symbol == "USDCAD") return 9;
      
      // Metals
      if(symbol == "XAUUSD") return 5;
      if(symbol == "XAGUSD") return 10;
      
      // Indices
      if(symbol == "US30") return 6;
      if(symbol == "NAS100") return 11;
      
      // Crypto
      if(symbol == "BTCUSD") return 7;
      
      // Default for unknown symbols
      return 99;
     }
  };

#endif // C_SWING_TRADING_STRATEGY_MQH
//+------------------------------------------------------------------+
