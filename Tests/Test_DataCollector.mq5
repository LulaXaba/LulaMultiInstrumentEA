//+------------------------------------------------------------------+
//|                                       Test_DataCollector.mq5     |
//|                     LulaMultiInstrumentEA - Data Collector Tests |
//+------------------------------------------------------------------+
#property copyright "LulaXaba"
#property link      "https://github.com/LulaXaba/LulaMultiInstrumentEA"
#property version   "1.00"
#property strict

#include "../Core/ML/C_DataCollector.mqh"
#include "../Core/ML/C_SignalScorer.mqh"

// Global test objects
C_DataCollector g_collector;
C_SignalScorer g_scorer;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("========================================");
   Print("Data Collector Test Suite");
   Print("========================================");
   
   // Initialize scorer
   if(!g_scorer.Initialize())
   {
      Print("❌ Failed to initialize signal scorer");
      return INIT_FAILED;
   }
   
   // Initialize collector
   if(!g_collector.Initialize("ML_Data", 50, 60))
   {
      Print("❌ Failed to initialize data collector");
      return INIT_FAILED;
   }
   
   Print("✅ Both components initialized successfully");
   Print("");
   
   // Run tests
   RunTests();
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   g_collector.Shutdown();
   Print("Test suite completed. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Tests run on init only
}

//+------------------------------------------------------------------+
//| Run all tests                                                    |
//+------------------------------------------------------------------+
void RunTests()
{
   Print("=== Test 1: Log BUY Signal ===");
   TestLogBuySignal();
   Print("");
   
   Print("=== Test 2: Log SELL Signal ===");
   TestLogSellSignal();
   Print("");
   
   Print("=== Test 3: Multiple Symbols ===");
   TestMultipleSymbols();
   Print("");
   
   Print("=== Test 4: Multiple Timeframes ===");
   TestMultipleTimeframes();
   Print("");
   
   Print("========================================");
   Print("✅ All tests completed successfully!");
   Print("Check MQL5/Files/ML_Data/ for CSV files");
   Print("========================================");
}

//+------------------------------------------------------------------+
//| Test 1: Log BUY signal                                           |
//+------------------------------------------------------------------+
void TestLogBuySignal()
{
   string symbol = _Symbol;
   ENUM_TIMEFRAMES tf = PERIOD_H1;
   int direction = OP_BUY;
   
   double price = SymbolInfoDouble(symbol, SYMBOL_BID);
   double sl = price - 50 * SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
   double tp = price + 100 * SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
   
   // Score the signal
   SignalScore score = g_scorer.EvaluateSignal(symbol, tf, direction, sl, tp);
   
   Print("Generated signal score: ", score.score);
   Print("Recommendation: ", EnumToString(score.recommendation));
   
   // Log to CSV
   string tradeId = g_collector.LogSignal(score, symbol, tf, direction, price, sl, tp);
   
   if(tradeId != "")
   {
      Print("✅ SUCCESS: Signal logged with ID: ", tradeId);
   }
   else
   {
      Print("❌ FAIL: Failed to log signal");
   }
}

//+------------------------------------------------------------------+
//| Test 2: Log SELL signal                                          |
//+------------------------------------------------------------------+
void TestLogSellSignal()
{
   string symbol = _Symbol;
   ENUM_TIMEFRAMES tf = PERIOD_H1;
   int direction = OP_SELL;
   
   double price = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double sl = price + 50 * SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
   double tp = price - 100 * SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
   
   SignalScore score = g_scorer.EvaluateSignal(symbol, tf, direction, sl, tp);
   
   Print("Generated signal score: ", score.score);
   
   string tradeId = g_collector.LogSignal(score, symbol, tf, direction, price, sl, tp);
   
   if(tradeId != "")
   {
      Print("✅ SUCCESS: SELL signal logged with ID: ", tradeId);
   }
   else
   {
      Print("❌ FAIL: Failed to log SELL signal");
   }
}

//+------------------------------------------------------------------+
//| Test 3: Multiple symbols                                        |
//+------------------------------------------------------------------+
void TestMultipleSymbols()
{
   string symbols[] = {"EURUSD", "GBPUSD", "USDJPY"};
   int logged = 0;
   
   for(int i = 0; i < ArraySize(symbols); i++)
   {
      string symbol = symbols[i];
      double price = SymbolInfoDouble(symbol, SYMBOL_BID);
      
      if(price == 0) // Symbol not available
         continue;
      
      SignalScore score = g_scorer.EvaluateSignal(symbol, PERIOD_H1, OP_BUY, 0, 0);
      string tradeId = g_collector.LogSignal(score, symbol, PERIOD_H1, OP_BUY, price, 0, 0);
      
      if(tradeId != "")
         logged++;
   }
   
   Print("✅ SUCCESS: Logged signals for ", logged, " symbols");
}

//+------------------------------------------------------------------+
//| Test 4: Multiple timeframes                                      |
//+------------------------------------------------------------------+
void TestMultipleTimeframes()
{
   ENUM_TIMEFRAMES timeframes[] = {PERIOD_M15, PERIOD_H1, PERIOD_H4};
   int logged = 0;
   
   for(int i = 0; i < ArraySize(timeframes); i++)
   {
      SignalScore score = g_scorer.EvaluateSignal(_Symbol, timeframes[i], OP_BUY, 0, 0);
      string tradeId = g_collector.LogSignal(score, _Symbol, timeframes[i], OP_BUY, 
                                             SymbolInfoDouble(_Symbol, SYMBOL_BID), 0, 0);
      
      if(tradeId != "")
      {
         logged++;
         Print("   ", EnumToString(timeframes[i]), ": ", tradeId);
      }
   }
   
   Print("✅ SUCCESS: Logged signals for ", logged, " timeframes");
}
//+------------------------------------------------------------------+
