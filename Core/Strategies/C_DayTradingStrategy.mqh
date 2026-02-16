//+------------------------------------------------------------------+
//|                                      C_DayTradingStrategy.mqh    |
//|                    Day Trading Strategy: H4 → H1 → M15           |
//|                           Intraday Scalping Opportunities        |
//+------------------------------------------------------------------+
#ifndef C_DAY_TRADING_STRATEGY_MQH
#define C_DAY_TRADING_STRATEGY_MQH

#include "../Strategies/IStrategy.mqh"
#include "../C_MarketAnalyzer.mqh"
#include "../Lula_CoreEnums.mqh"

//+------------------------------------------------------------------+
//| Day Trading Strategy Class                                        |
//| Timeframes: H4 (trend) → H1 (confirmation) → M15 (execution)      |
//| Target: 15-20 trades/month per symbol, 60-65% win rate           |
//+------------------------------------------------------------------+
class C_DayTradingStrategy : public IStrategy
  {
private:
   ENUM_TIMEFRAMES    m_primaryTF;      // H4 - Primary trend
   ENUM_TIMEFRAMES    m_secondaryTF;    // H1 - Confirmation
   ENUM_TIMEFRAMES    m_executionTF;    // M15 - Entry trigger
   C_MarketAnalyzer  *m_market;         // Market data provider

public:
   //+------------------------------------------------------------------+
   //| Constructor                                                       |
   //+------------------------------------------------------------------+
   C_DayTradingStrategy(void)
     {
      m_primaryTF = PERIOD_H4;
      m_secondaryTF = PERIOD_H1;
      m_executionTF = PERIOD_M15;
      m_market = NULL;
     }
   
   //+------------------------------------------------------------------+
   //| Destructor                                                        |
   //+------------------------------------------------------------------+
   ~C_DayTradingStrategy(void)
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
         Print("ERROR: DayTradingStrategy - NULL market analyzer");
         return false;
        }
      
      m_market = marketAnalyzer;
      PrintFormat("✅ Day Trading Strategy initialized (H4→H1→M15)");
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
      TimeframeAnalysis h4  = m_market.GetAnalysis(PERIOD_H4);
      TimeframeAnalysis h1  = m_market.GetAnalysis(PERIOD_H1);
      TimeframeAnalysis m15 = m_market.GetAnalysis(PERIOD_M15);
      
      // RULE 1: H4 must show clear directional trend (not sideways)
      if(h4.trend == TREND_SIDEWAYS || h4.trend == TREND_UNKNOWN)
        {
         return PATTERN_NONE;
        }
      
      // RULE 2: H1 must align with H4 trend
      if(h4.trend != h1.trend)
        {
         return PATTERN_NONE;
        }
      
      // RULE 3: M15 pattern must align with H4/H1 trend direction
      if(h4.trend == TREND_UP)
        {
         // Look for bullish patterns on M15
         if(IsBullishPattern(m15.pattern))
           {
            PrintFormat("📊 DayTrading BUY: H4=%s, H1=%s, M15 Pattern=%s", 
                       EnumToString(h4.trend), 
                       EnumToString(h1.trend),
                       EnumToString(m15.pattern));
            return m15.pattern;
           }
        }
      else if(h4.trend == TREND_DOWN)
        {
         // Look for bearish patterns on M15
         if(IsBearishPattern(m15.pattern))
           {
            PrintFormat("📊 DayTrading SELL: H4=%s, H1=%s, M15 Pattern=%s", 
                       EnumToString(h4.trend), 
                       EnumToString(h1.trend),
                       EnumToString(m15.pattern));
            return m15.pattern;
           }
        }
      
      return PATTERN_NONE;
     }
   
   //+------------------------------------------------------------------+
   //| Get strategy name                                                |
   //+------------------------------------------------------------------+
   virtual string GetStrategyName(void)
     {
      return "DayTrading";
     }
   
   //+------------------------------------------------------------------+
   //| Get magic number for this strategy and symbol                    |
   //| Format: 1XXX where XXX is symbol code                           |
   //+------------------------------------------------------------------+
   int GetMagicNumber(string symbol)
     {
      int symbolCode = GetSymbolCode(symbol);
      return STRATEGY_DAY_TRADING + symbolCode;  // 1000 + code
     }
   
   //+------------------------------------------------------------------+
   //| Get primary timeframe (H4)                                       |
   //+------------------------------------------------------------------+
   ENUM_TIMEFRAMES GetPrimaryTimeframe(void)
     {
      return m_primaryTF;
     }
   
   //+------------------------------------------------------------------+
   //| Get execution timeframe (M15)                                    |
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

#endif // C_DAY_TRADING_STRATEGY_MQH
//+------------------------------------------------------------------+
