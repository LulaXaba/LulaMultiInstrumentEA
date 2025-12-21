//+------------------------------------------------------------------+
//|                                                C_TrendDetector.mqh |
//+------------------------------------------------------------------+
#ifndef LULA_TREND_DETECTOR_MQH
#define LULA_TREND_DETECTOR_MQH

#include "Lula_CoreEnums.mqh"
#include <Object.mqh>
#include "C_AdaptiveMA.mqh"

class C_TrendDetector
  {
private:
   C_AdaptiveMA*      m_hFastMA;
   C_AdaptiveMA*      m_hSlowMA;
   string             m_symbol;
   ENUM_TIMEFRAMES    m_timeframe;
   bool               m_ready; // NEW: Track if data is ready

public:
   C_TrendDetector(void) : m_hFastMA(NULL), m_hSlowMA(NULL), m_ready(false) {}
     
  ~C_TrendDetector(void)
     {
      if(CheckPointer(m_hFastMA) != POINTER_INVALID) delete m_hFastMA;
      if(CheckPointer(m_hSlowMA) != POINTER_INVALID) delete m_hSlowMA;
     }
     
   bool Initialize(string symbol, ENUM_TIMEFRAMES timeframe,
                   int fastLen, int fastSlow, int fastER,
                   int slowLen, int slowSlow, int slowER)
     {
      m_symbol = symbol;
      m_timeframe = timeframe;
      
      m_hFastMA = new C_AdaptiveMA();
      if(!m_hFastMA.Initialize(m_symbol, m_timeframe, fastLen, fastSlow, fastER))
        {
         Print("ERROR: Failed to initialize Fast MA");
         return false;
        }
      
      m_hSlowMA = new C_AdaptiveMA();
      if(!m_hSlowMA.Initialize(m_symbol, m_timeframe, slowLen, slowSlow, slowER))
        {
         Print("ERROR: Failed to initialize Slow MA");
         return false;
        }

      PrintFormat("C_TrendDetector: Initialized for %s %s", symbol, EnumToString(timeframe));
      return true;
     }

   //--- FIXED: Error handling + logging
   bool Calculate(int bars)
     {
      if(CheckPointer(m_hFastMA) == POINTER_INVALID || CheckPointer(m_hSlowMA) == POINTER_INVALID)
        {
         Print("ERROR: MA pointers invalid");
         return false;
        }
      
      if(!m_hFastMA.Calculate(bars))
        {
         PrintFormat("ERROR: Fast MA calculation failed on %s", EnumToString(m_timeframe));
         m_ready = false;
         return false;
        }
        
      if(!m_hSlowMA.Calculate(bars))
        {
         PrintFormat("ERROR: Slow MA calculation failed on %s", EnumToString(m_timeframe));
         m_ready = false;
         return false;
        }
      
      m_ready = true;
      return true;
     }
     
   ENUM_TREND_DIRECTION GetTrendDirection(void)
     {
      if(!m_ready)
        {
         static datetime last_warn = 0;
         if(TimeCurrent() - last_warn > 3600) // Warn once per hour
           {
            PrintFormat("WARNING: Trend data not ready for %s", EnumToString(m_timeframe));
            last_warn = TimeCurrent();
           }
         return TREND_UNKNOWN;
        }
      
      double fastMA = m_hFastMA.GetValue(1);
      double slowMA = m_hSlowMA.GetValue(1);
      
      if(fastMA == 0.0 || slowMA == 0.0)
        {
         PrintFormat("ERROR: Zero MA values. Fast=%.5f, Slow=%.5f", fastMA, slowMA);
         return TREND_UNKNOWN;
        }

      //--- FIX: Minimum Separation Threshold (10 Points)
      double separation = MathAbs(fastMA - slowMA);
      double minThreshold = 10 * SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      
      if(separation < minThreshold) return TREND_SIDEWAYS; // Too close = Noise

      if(fastMA > slowMA) return TREND_UP;
      if(fastMA < slowMA) return TREND_DOWN;
      return TREND_SIDEWAYS;
     }
     
   double GetTrendStrength(void) { return 0.0; }
     
   double GetFastMAValue(int shift)
     {
      if(CheckPointer(m_hFastMA) == POINTER_INVALID) return 0.0;
      return m_hFastMA.GetValue(shift);
     }
     
   double GetSlowMAValue(int shift)
     {
      if(CheckPointer(m_hSlowMA) == POINTER_INVALID) return 0.0;
      return m_hSlowMA.GetValue(shift);
     }
     
   //--- NEW: Diagnostics
   void PrintDiagnostics()
     {
      PrintFormat("=== %s TrendDetector ===", EnumToString(m_timeframe));
      if(CheckPointer(m_hFastMA) != POINTER_INVALID) m_hFastMA.PrintDiagnostics();
      if(CheckPointer(m_hSlowMA) != POINTER_INVALID) m_hSlowMA.PrintDiagnostics();
     }
  };
#endif
