//+------------------------------------------------------------------+
//|                                                     C_ZigZag.mqh |
//|           ZigZag Swing Detection Class for EA Integration        |
//|               Converted from FastZZ.mq5 indicator logic          |
//+------------------------------------------------------------------+
#ifndef LULA_ZIGZAG_MQH
#define LULA_ZIGZAG_MQH

#include "Lula_CoreEnums.mqh"

//+------------------------------------------------------------------+
//| ZigZag Swing Detection Class                                      |
//| Identifies swing highs and lows for structure analysis           |
//+------------------------------------------------------------------+
class C_ZigZag
  {
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;
   int               m_depth;              // Minimum points in a swing
   double            m_depthPrice;         // Depth in price terms
   int               m_direction;          // 1 = up (looking for highs), -1 = down (looking for lows)
   int               m_lastIndex;          // Index of last confirmed swing point
   
   //--- Swing buffers (stores swing point prices, 0 = no swing at that bar)
   double            m_swingHighs[];
   double            m_swingLows[];
   int               m_bufferSize;
   
   //--- Recent swing points cache for harmonic detection
   SwingPoint        m_recentSwings[];
   int               m_recentSwingsCount;
   int               m_maxRecentSwings;

public:
   //--- Constructor
   C_ZigZag(void)
     {
      m_symbol = "";
      m_timeframe = PERIOD_CURRENT;
      m_depth = 100;
      m_depthPrice = 0;
      m_direction = 1;
      m_lastIndex = 0;
      m_bufferSize = 0;
      m_recentSwingsCount = 0;
      m_maxRecentSwings = 10;  // Store last 10 swing points
     }

   //--- Destructor
   ~C_ZigZag(void)
     {
      ArrayFree(m_swingHighs);
      ArrayFree(m_swingLows);
      ArrayFree(m_recentSwings);
     }

   //--- Initialize the ZigZag detector
   bool Initialize(string symbol, ENUM_TIMEFRAMES timeframe, int depthPoints = 100)
     {
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_depth = depthPoints;
      m_depthPrice = depthPoints * SymbolInfoDouble(symbol, SYMBOL_POINT);
      m_direction = 1;
      m_lastIndex = 0;
      m_recentSwingsCount = 0;
      
      //--- Allocate recent swings array
      if(ArrayResize(m_recentSwings, m_maxRecentSwings) < m_maxRecentSwings)
         return false;
         
      return true;
     }

   //--- Calculate ZigZag on price data
   //--- Returns true if new swing points were detected
   bool Calculate(int barsToProcess = 300)
     {
      //--- Get price data
      MqlRates rates[];
      int copied = CopyRates(m_symbol, m_timeframe, 0, barsToProcess, rates);
      if(copied < 10)
         return false;
         
      ArraySetAsSeries(rates, false);  // Oldest first (index 0 = oldest)
      
      int total = copied;
      
      //--- Resize buffers if needed
      if(m_bufferSize != total)
        {
         if(ArrayResize(m_swingHighs, total) < total) return false;
         if(ArrayResize(m_swingLows, total) < total) return false;
         ArrayInitialize(m_swingHighs, 0);
         ArrayInitialize(m_swingLows, 0);
         m_bufferSize = total;
         m_lastIndex = 0;
         m_direction = 1;
        }
      
      //--- Process bars (adapted from FastZZ logic)
      for(int i = (m_lastIndex > 0 ? m_lastIndex : 0); i < total - 1; i++)
        {
         bool set = false;
         m_swingLows[i] = 0;
         m_swingHighs[i] = 0;
         
         double high_i = rates[i].high;
         double low_i = rates[i].low;
         double open_i = rates[i].open;
         double close_i = rates[i].close;
         
         if(m_direction > 0)  // Looking for swing highs
           {
            double lastHigh = (m_lastIndex >= 0 && m_lastIndex < total) ? m_swingHighs[m_lastIndex] : 0;
            
            if(lastHigh > 0 && high_i > lastHigh)
              {
               m_swingHighs[m_lastIndex] = 0;
               m_swingHighs[i] = high_i;
               
               if(low_i < lastHigh - m_depthPrice)
                 {
                  if(open_i < close_i)
                     m_swingHighs[m_lastIndex] = rates[m_lastIndex].high;
                  else
                     m_direction = -1;
                  m_swingLows[i] = low_i;
                 }
               m_lastIndex = i;
               set = true;
              }
            
            if(lastHigh > 0 && low_i < lastHigh - m_depthPrice && (!set || open_i > close_i))
              {
               m_swingLows[i] = low_i;
               if(high_i > low_i + m_depthPrice && open_i < close_i)
                  m_swingHighs[i] = high_i;
               else
                  m_direction = -1;
               m_lastIndex = i;
              }
           }
         else  // Looking for swing lows (direction < 0)
           {
            double lastLow = (m_lastIndex >= 0 && m_lastIndex < total) ? m_swingLows[m_lastIndex] : 0;
            
            if(lastLow > 0 && low_i < lastLow)
              {
               m_swingLows[m_lastIndex] = 0;
               m_swingLows[i] = low_i;
               
               if(high_i > lastLow + m_depthPrice)
                 {
                  if(open_i > close_i)
                     m_swingLows[m_lastIndex] = rates[m_lastIndex].low;
                  else
                     m_direction = 1;
                  m_swingHighs[i] = high_i;
                 }
               m_lastIndex = i;
               set = true;
              }
            
            if(lastLow > 0 && high_i > lastLow + m_depthPrice && (!set || open_i < close_i))
              {
               m_swingHighs[i] = high_i;
               if(low_i < high_i - m_depthPrice && open_i > close_i)
                  m_swingLows[i] = low_i;
               else
                  m_direction = 1;
               m_lastIndex = i;
              }
           }
        }
      
      //--- Build recent swings cache from buffers
      BuildRecentSwingsCache(rates, total);
      
      return true;
     }

   //--- Get the most recent swing high price
   double GetLastSwingHigh(int shift = 0)
     {
      int found = 0;
      for(int i = m_bufferSize - 1; i >= 0; i--)
        {
         if(m_swingHighs[i] > 0)
           {
            if(found == shift)
               return m_swingHighs[i];
            found++;
           }
        }
      return 0;
     }

   //--- Get the most recent swing low price
   double GetLastSwingLow(int shift = 0)
     {
      int found = 0;
      for(int i = m_bufferSize - 1; i >= 0; i--)
        {
         if(m_swingLows[i] > 0)
           {
            if(found == shift)
               return m_swingLows[i];
            found++;
           }
        }
      return 0;
     }

   //--- Get bar index of the most recent swing high
   int GetLastSwingHighIndex(int shift = 0)
     {
      int found = 0;
      for(int i = m_bufferSize - 1; i >= 0; i--)
        {
         if(m_swingHighs[i] > 0)
           {
            if(found == shift)
               return m_bufferSize - 1 - i;  // Convert to "bars ago" format
            found++;
           }
        }
      return -1;
     }

   //--- Get bar index of the most recent swing low
   int GetLastSwingLowIndex(int shift = 0)
     {
      int found = 0;
      for(int i = m_bufferSize - 1; i >= 0; i--)
        {
         if(m_swingLows[i] > 0)
           {
            if(found == shift)
               return m_bufferSize - 1 - i;  // Convert to "bars ago" format
            found++;
           }
        }
      return -1;
     }

   //--- Get current swing direction (1 = bullish/up, -1 = bearish/down)
   int GetCurrentDirection(void)
     {
      return m_direction;
     }

   //--- Get recent swing points for harmonic pattern detection
   //--- Returns points in order from oldest (X) to newest (D)
   bool GetRecentSwingPoints(SwingPoint &points[], int count)
     {
      if(count > m_recentSwingsCount)
         return false;
      
      if(ArrayResize(points, count) < count)
         return false;
      
      //--- Copy the most recent 'count' points (oldest first for X-A-B-C-D order)
      int startIdx = m_recentSwingsCount - count;
      for(int i = 0; i < count; i++)
        {
         points[i] = m_recentSwings[startIdx + i];
        }
      
      return true;
     }

   //--- Get count of cached recent swings
   int GetRecentSwingsCount(void)
     {
      return m_recentSwingsCount;
     }

private:
   //--- Build cache of recent swing points from buffers
   void BuildRecentSwingsCache(const MqlRates &rates[], int total)
     {
      m_recentSwingsCount = 0;
      
      //--- Collect all swing points
      SwingPoint tempSwings[];
      int tempCount = 0;
      
      for(int i = 0; i < total && tempCount < 100; i++)
        {
         if(m_swingHighs[i] > 0)
           {
            ArrayResize(tempSwings, tempCount + 1);
            tempSwings[tempCount].price = m_swingHighs[i];
            tempSwings[tempCount].time = rates[i].time;
            tempSwings[tempCount].barIndex = total - 1 - i;  // Bars ago
            tempSwings[tempCount].isHigh = true;
            tempCount++;
           }
         if(m_swingLows[i] > 0)
           {
            ArrayResize(tempSwings, tempCount + 1);
            tempSwings[tempCount].price = m_swingLows[i];
            tempSwings[tempCount].time = rates[i].time;
            tempSwings[tempCount].barIndex = total - 1 - i;  // Bars ago
            tempSwings[tempCount].isHigh = false;
            tempCount++;
           }
        }
      
      //--- Keep only the most recent ones (up to m_maxRecentSwings)
      int copyCount = MathMin(tempCount, m_maxRecentSwings);
      int startIdx = tempCount - copyCount;
      
      for(int i = 0; i < copyCount; i++)
        {
         m_recentSwings[i] = tempSwings[startIdx + i];
        }
      m_recentSwingsCount = copyCount;
     }
  };

#endif // LULA_ZIGZAG_MQH
//+------------------------------------------------------------------+
