//+------------------------------------------------------------------+
//|                                                    IStrategy.mqh |
//|                                  Interface for Trading Strategies |
//+------------------------------------------------------------------+
#ifndef ISTRATEGY_MQH
#define ISTRATEGY_MQH

#include "..\Lula_CoreEnums.mqh"
#include "..\C_MarketAnalyzer.mqh"

//+------------------------------------------------------------------+
//| Interface for all trading strategies                             |
//+------------------------------------------------------------------+
class IStrategy
  {
public:
   //--- Destructor
   virtual ~IStrategy() {}

   //--- Initialize the strategy
   virtual bool Initialize(C_MarketAnalyzer *marketAnalyzer) = 0;

   //--- Check for entry signals
   //--- Returns PATTERN_NONE if no signal, or a specific pattern enum if a signal exists
   virtual ENUM_SIGNAL_PATTERN CheckEntrySignal(void) = 0;

   //--- Get the name of the strategy
   virtual string GetStrategyName(void) = 0;
  };

#endif // ISTRATEGY_MQH
