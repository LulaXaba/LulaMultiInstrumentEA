//+------------------------------------------------------------------+
//|                                            Test_StrategyLoad.mq5 |
//| Script to verify that Strategy Pattern components compile and load |
//+------------------------------------------------------------------+
#property script_show_inputs

#include "..\Core\Strategies\C_LulaStrategy.mqh"
#include "..\Execution\C_SignalEngine.mqh"
#include "..\Core\C_MarketAnalyzer.mqh"
#include "..\Instruments\C_InstrumentConfig.mqh"

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   Print("=== Testing Strategy Pattern Components ===");

   // 1. Test Configuration Creation
   C_InstrumentConfig *config = new C_InstrumentConfig();
   if(CheckPointer(config) == POINTER_INVALID)
     {
      Print("FAILED: Could not create InstrumentConfig");
      return;
     }
   Print("PASSED: InstrumentConfig created");

   // 2. Test Market Analyzer Creation
   C_MarketAnalyzer *analyzer = new C_MarketAnalyzer();
   if(CheckPointer(analyzer) == POINTER_INVALID)
     {
      Print("FAILED: Could not create MarketAnalyzer");
      delete config;
      return;
     }
   
   // Initialize Analyzer (using dummy values for test)
   if(!analyzer.Initialize(_Symbol, config))
     {
      Print("FAILED: Could not initialize MarketAnalyzer");
      delete config;
      delete analyzer;
      return;
     }

   // Add timeframes separately:
   if(!analyzer.AddTimeframe(PERIOD_M15, 9, 14, 5, 26, 52, 5))
     {
      Print("FAILED: Could not add M15 timeframe");
      delete config;
      delete analyzer;
      return;
     }

   if(!analyzer.AddTimeframe(PERIOD_H1, 9, 14, 5, 26, 52, 5))
     {
      Print("FAILED: Could not add H1 timeframe");
      delete config;
      delete analyzer;
      return;
     }
   Print("PASSED: MarketAnalyzer created and initialized");

   // 3. Test Strategy Creation
   C_LulaStrategy *strategy = new C_LulaStrategy();
   if(CheckPointer(strategy) == POINTER_INVALID)
     {
      Print("FAILED: Could not create LulaStrategy");
      delete config;
      delete analyzer;
      return;
     }
   Print("PASSED: LulaStrategy created");

   // 4. Test Signal Engine Creation and Wiring
   C_SignalEngine *engine = new C_SignalEngine();
   if(CheckPointer(engine) == POINTER_INVALID)
     {
      Print("FAILED: Could not create SignalEngine");
      delete config;
      delete analyzer;
      delete strategy;
      return;
     }
   
   if(!engine.Initialize(analyzer))
     {
      Print("FAILED: Could not initialize SignalEngine");
      delete config;
      delete analyzer;
      delete strategy;
      delete engine;
      return;
     }
     
   engine.SetStrategy(strategy);
   Print("PASSED: SignalEngine created and Strategy injected");

   // 5. Cleanup
   delete engine; // Engine does not own strategy/analyzer in our design
   delete strategy;
   delete analyzer;
   delete config;
   
   Print("=== ALL TESTS PASSED ===");
  }
