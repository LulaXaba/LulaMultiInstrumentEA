//+------------------------------------------------------------------+
//|                                          Test_HarmonicPattern.mq5|
//|                    Test Script for Harmonic Pattern Detection    |
//+------------------------------------------------------------------+
#property copyright "Lula EA"
#property version   "1.00"
#property script_show_inputs

//--- Include the necessary files
#include "..\Core\C_ZigZag.mqh"
#include "..\Core\C_HarmonicRecognizer.mqh"

//--- Input parameters
input int    InpZigZagDepth  = 100;     // ZigZag Depth (points)
input int    InpBarsToAnalyze = 300;    // Bars to analyze
input double InpSlackRange   = 0.01;    // Fibonacci slack (range)
input double InpSlackUnary   = 0.1;     // Fibonacci slack (unary)

//+------------------------------------------------------------------+
//| Script program start function                                     |
//+------------------------------------------------------------------+
void OnStart()
  {
   Print("=== Harmonic Pattern Detection Test ===");
   Print("Symbol: ", _Symbol);
   Print("Timeframe: ", EnumToString(Period()));
   Print("");
   
   //--- 1. Test ZigZag Detection
   Print("--- Testing ZigZag Detection ---");
   
   C_ZigZag zigzag;
   if(!zigzag.Initialize(_Symbol, Period(), InpZigZagDepth))
     {
      Print("ERROR: Failed to initialize ZigZag");
      return;
     }
   
   if(!zigzag.Calculate(InpBarsToAnalyze))
     {
      Print("ERROR: Failed to calculate ZigZag");
      return;
     }
   
   Print("ZigZag initialized successfully!");
   Print("  Last Swing High: ", zigzag.GetLastSwingHigh(0));
   Print("  Last Swing Low:  ", zigzag.GetLastSwingLow(0));
   Print("  Direction: ", zigzag.GetCurrentDirection() > 0 ? "BULLISH (up)" : "BEARISH (down)");
   Print("  Recent Swings Count: ", zigzag.GetRecentSwingsCount());
   Print("");
   
   //--- 2. Test Harmonic Pattern Recognition
   Print("--- Testing Harmonic Recognition ---");
   
   C_HarmonicRecognizer harmonic;
   if(!harmonic.Initialize(InpSlackRange, InpSlackUnary))
     {
      Print("ERROR: Failed to initialize HarmonicRecognizer");
      return;
     }
   
   Print("HarmonicRecognizer initialized successfully!");
   
   //--- Get swing points for harmonic detection
   SwingPoint swings[];
   if(zigzag.GetRecentSwingPoints(swings, 5))
     {
      Print("Retrieved 5 swing points for harmonic analysis:");
      for(int i = 0; i < 5; i++)
        {
         Print("  Point ", i, ": ", swings[i].isHigh ? "HIGH" : "LOW", 
               " @ ", swings[i].price, 
               " (", TimeToString(swings[i].time), ")");
        }
      Print("");
      
      //--- Check for harmonic patterns
      HarmonicPatternResult result;
      ENUM_HARMONIC_PATTERN detected = harmonic.CheckPatterns(swings, result);
      
      if(detected != HARMONIC_NONE)
        {
         Print("*** HARMONIC PATTERN DETECTED! ***");
         Print("  Pattern: ", harmonic.PatternToString(detected));
         Print("  Direction: ", result.isBullish ? "BULLISH" : "BEARISH");
         Print("  Confidence: ", DoubleToString(result.confidence * 100, 1), "%");
         Print("  PRZ Zone: ", result.prz_low, " - ", result.prz_high);
         Print("  X: ", result.X);
         Print("  A: ", result.A);
         Print("  B: ", result.B);
         Print("  C: ", result.C);
         Print("  D: ", result.D);
        }
      else
        {
         Print("No harmonic pattern detected at current swing structure.");
         Print("This is normal - harmonic patterns are rare.");
        }
     }
   else
     {
      Print("Not enough swing points for harmonic analysis (need 5).");
      Print("Available swings: ", zigzag.GetRecentSwingsCount());
     }
   
   Print("");
   Print("=== Test Complete ===");
  }
//+------------------------------------------------------------------+
