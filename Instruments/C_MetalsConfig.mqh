//+------------------------------------------------------------------+
//|                                             C_MetalsConfig.mqh   |
//|                                  Metals (Gold/Silver) Config     |
//+------------------------------------------------------------------+
#property copyright "LulaMultiInstrumentEA"
#property version   "1.00"
#property strict

#include "C_InstrumentConfig.mqh"

//+------------------------------------------------------------------+
//| Metals Configuration Class (Gold, Silver, Platinum, Palladium)  |
//+------------------------------------------------------------------+
class C_MetalsConfig : public C_InstrumentConfig
{
public:
   C_MetalsConfig(void) : C_InstrumentConfig()
   {
      m_maxRiskPercent = 2.5;   // Slightly lower risk for volatile metals
      m_maxSpreadPips = 10.0;   // Much higher tolerance for gold/silver spreads
      
      PrintFormat("✅ C_MetalsConfig Initialized for %s. Max Risk: %.2f%%, Max Spread: %.1f pips",
         m_symbol, m_maxRiskPercent, m_maxSpreadPips);
   }
   
   virtual ~C_MetalsConfig() {}
};
