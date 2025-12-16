//+------------------------------------------------------------------+
//|                                          Test_TrendDetector.mq5  |
//+------------------------------------------------------------------+
#property script_show_inputs

#include "Core/C_TrendDetector.mqh"

void OnStart()
  {
   C_TrendDetector* detector = new C_TrendDetector();
   
   if(!detector.Initialize(_Symbol, PERIOD_H1, 9, 14, 5, 26, 52, 5))
     {
      Print("? Failed to initialize");
      delete detector;
      return;
     }
   
   // Test the methods that are causing errors
   double fast1 = detector.GetFastMAValue(1);
   double slow1 = detector.GetSlowMAValue(1);
   
   Print("? Test Passed!");
   Print("Fast MA[1]: ", fast1);
   Print("Slow MA[1]: ", slow1);
   
   delete detector;
  }
