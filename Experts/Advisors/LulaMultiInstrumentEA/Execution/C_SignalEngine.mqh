//+------------------------------------------------------------------+
//|                                               C_SignalEngine.mqh |
//|  Context class for the Strategy Pattern. Delegates to IStrategy. |
//+------------------------------------------------------------------+
#ifndef LULA_SIGNAL_ENGINE_MQH
#define LULA_SIGNAL_ENGINE_MQH

#include "..\Core\Strategies\IStrategy.mqh"
#include "..\Core\C_MarketAnalyzer.mqh"

class C_SignalEngine
  {
private:
   IStrategy        *m_strategy;
   C_MarketAnalyzer *m_marketAnalyzer;

public:
   //--- Constructor
   C_SignalEngine(void)
     {
      m_strategy = NULL;
      m_marketAnalyzer = NULL;
     }

   //--- Destructor
   ~C_SignalEngine(void)
     {
      // We do NOT delete the strategy or analyzer here as they are injected
      // and should be managed by the main EA or a factory.
      // However, if we want SignalEngine to own the strategy, we could delete it.
      // For now, let's assume external ownership or simple pointer reference.
      // EDIT: To be safe and avoid leaks if we create it in OnInit, let's leave cleanup to the creator
      // OR we can add a method to explicitly set ownership.
     }

   //--- Initialize
   bool Initialize(C_MarketAnalyzer *marketAnalyzer)
     {
      if(marketAnalyzer == NULL) return false;
      m_marketAnalyzer = marketAnalyzer;
      return true;
     }

   //--- Set the Strategy
   void SetStrategy(IStrategy *strategy)
     {
      m_strategy = strategy;
      // Also initialize the strategy with the market analyzer
      if(m_strategy != NULL && m_marketAnalyzer != NULL)
        {
         m_strategy.Initialize(m_marketAnalyzer);
        }
     }

   //--- Check for Entry Signal
   ENUM_SIGNAL_PATTERN CheckEntrySignal(void)
     {
      if(m_strategy == NULL) return PATTERN_NONE;
      
      // First, ensure Market Analyzer has run its analysis for this tick
      // (Assuming Analyze() is called in the main EA before this)
      
      return m_strategy.CheckEntrySignal();
     }
  };

#endif // LULA_SIGNAL_ENGINE_MQH
