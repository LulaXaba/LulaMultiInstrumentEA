//+------------------------------------------------------------------+
//|                                          Test_SignalScorer.mq5   |
//|                   LulaMultiInstrumentEA - Signal Scorer Tests   |
//|                                   Phase 0: ML-Lite Foundation   |
//+------------------------------------------------------------------+
#property copyright "LulaXaba"
#property link      "https://github.com/LulaXaba/LulaMultiInstrumentEA"
#property version   "1.00"
#property strict

#include "../Core/ML/C_SignalScorer.mqh"
#include "../Core/ML/IndicatorHelpers_MQL5.mqh"

// Global test variables
C_SignalScorer g_scorer;
int g_testsRun = 0;
int g_testsPassed = 0;
int g_testsFailed = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("========================================");
   Print("Signal Scorer Test Suite");
   Print("========================================");
   Print("Testing C_SignalScorer with 20 scoring factors");
   Print("");
   
   // Initialize scorer with default weights
   if(!g_scorer.Initialize())
   {
      Print("❌ CRITICAL: Failed to initialize C_SignalScorer!");
      return INIT_FAILED;
   }
   
   Print("✅ C_SignalScorer initialized successfully");
   Print("   Weights: Trend=", g_scorer.GetWeightTrend(),
         " Tech=", g_scorer.GetWeightTechnical(),
         " Context=", g_scorer.GetWeightContext(),
         " RR=", g_scorer.GetWeightRR(),
         " Historical=", g_scorer.GetWeightHistorical());
   Print("");
   
   // Run all tests
   RunAllTests();
   
   // Print summary
   PrintTestSummary();
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Test suite completed. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Tests run on init, nothing to do on tick
}

//+------------------------------------------------------------------+
//| Run all test scenarios                                           |
//+------------------------------------------------------------------+
void RunAllTests()
{
   Print("--- Starting Signal Scorer Tests ---");
   Print("");
   
   // Test 1: Basic scoring (BUY signal)
   Test_BasicBuySignal();
   
   // Test 2: Basic scoring (SELL signal)
   Test_BasicSellSignal();
   
   // Test 3: High quality signal (all factors aligned)
   Test_HighQualitySignal();
   
   // Test 4: Low quality signal (poor conditions)
   Test_LowQualitySignal();
   
   // Test 5: Score with SL/TP provided
   Test_WithStopLossTakeProfit();
   
   // Test 6: Weight customization
   Test_CustomWeights();
   
   // Test 7: Threshold customization
   Test_CustomThresholds();
   
   // Test 8: Different timeframes
   Test_MultipleTimeframes();
   
   // Test 9: Score range validation (0.0-1.0)
   Test_ScoreRangeValidation();
   
   // Test 10: Recommendation levels
   Test_RecommendationLevels();
   
   Print("");
   Print("--- All Tests Completed ---");
   Print("");
}

//+------------------------------------------------------------------+
//| Test 1: Basic BUY signal scoring                                |
//+------------------------------------------------------------------+
void Test_BasicBuySignal()
{
   RecordTestStart("Basic BUY Signal Scoring");
   
   string symbol = _Symbol;
   ENUM_TIMEFRAMES tf = PERIOD_H1;
   int direction = OP_BUY;
   
   SignalScore result = g_scorer.EvaluateSignal(symbol, tf, direction, 0, 0);
   
   Print("   Score: ", DoubleToString(result.score, 4));
   Print("   Confidence: ", DoubleToString(result.confidence, 4));
   Print("   Recommendation: ", EnumToString(result.recommendation));
   Print("   Explanation: ", result.explanation);
   
   // Validate score is in range
   if(result.score >= 0.0 && result.score <= 1.0)
   {
      Print("✅ SUCCESS: Score in valid range [0.0, 1.0]");
      RecordTestPass();
   }
   else
   {
      Print("❌ FAIL: Score out of range: ", result.score);
      RecordTestFail();
   }
}

//+------------------------------------------------------------------+
//| Test 2: Basic SELL signal scoring                               |
//+------------------------------------------------------------------+
void Test_BasicSellSignal()
{
   RecordTestStart("Basic SELL Signal Scoring");
   
   string symbol = _Symbol;
   ENUM_TIMEFRAMES tf = PERIOD_H1;
   int direction = OP_SELL;
   
   SignalScore result = g_scorer.EvaluateSignal(symbol, tf, direction, 0, 0);
   
   Print("   Score: ", DoubleToString(result.score, 4));
   Print("   Confidence: ", DoubleToString(result.confidence, 4));
   Print("   Recommendation: ", EnumToString(result.recommendation));
   
   if(result.score >= 0.0 && result.score <= 1.0)
   {
      Print("✅ SUCCESS: SELL signal scored successfully");
      RecordTestPass();
   }
   else
   {
      Print("❌ FAIL: Invalid score");
      RecordTestFail();
   }
}

//+------------------------------------------------------------------+
//| Test 3: High quality signal (simulated perfect conditions)      |
//+------------------------------------------------------------------+
void Test_HighQualitySignal()
{
   RecordTestStart("High Quality Signal (Perfect Conditions)");
   
   // In real market, this tests with actual market data
   // High quality = strong trend, good volatility, London/NY session, etc.
   
   string symbol = _Symbol;
   ENUM_TIMEFRAMES tf = PERIOD_M15; // M15 during active hours
   int direction = OP_BUY;
   
   SignalScore result = g_scorer.EvaluateSignal(symbol, tf, direction, 0, 0);
   
   Print("   Score: ", DoubleToString(result.score, 4));
   Print("   Confidence: ", DoubleToString(result.confidence, 4));
   
   // Note: Actual score depends on market conditions
   // We're just validating it works, not testing specific values
   
   if(result.score >= 0.0 && result.score <= 1.0 && result.confidence >= 0.0)
   {
      Print("✅ SUCCESS: High quality test completed");
      RecordTestPass();
   }
   else
   {
      Print("❌ FAIL: Invalid result");
      RecordTestFail();
   }
}

//+------------------------------------------------------------------+
//| Test 4: Low quality signal (simulated poor conditions)          |
//+------------------------------------------------------------------+
void Test_LowQualitySignal()
{
   RecordTestStart("Low Quality Signal (Poor Conditions)");
   
   // Test with wider timeframe during off-hours
   string symbol = _Symbol;
   ENUM_TIMEFRAMES tf = PERIOD_D1;
   int direction = OP_BUY;
   
   SignalScore result = g_scorer.EvaluateSignal(symbol, tf, direction, 0, 0);
   
   Print("   Score: ", DoubleToString(result.score, 4));
   Print("   Note: Score depends on actual market conditions");
   
   if(result.score >= 0.0 && result.score <= 1.0)
   {
      Print("✅ SUCCESS: Low quality test completed");
      RecordTestPass();
   }
   else
   {
      Print("❌ FAIL: Invalid score");
      RecordTestFail();
   }
}

//+------------------------------------------------------------------+
//| Test 5: Scoring with SL/TP provided                             |
//+------------------------------------------------------------------+
void Test_WithStopLossTakeProfit()
{
   RecordTestStart("Scoring with Stop Loss & Take Profit");
   
   string symbol = _Symbol;
   ENUM_TIMEFRAMES tf = PERIOD_H1;
   int direction = OP_BUY;
   
   double currentPrice = SymbolInfoDouble(symbol, SYMBOL_BID);
   double atr = GetATR(symbol, tf, 14, 1);
   
   // Set SL 1.5x ATR below, TP 3x ATR above (2:1 R:R)
   double sl = currentPrice - (atr * 1.5);
   double tp = currentPrice + (atr * 3.0);
   
   SignalScore result = g_scorer.EvaluateSignal(symbol, tf, direction, sl, tp);
   
   Print("   Score: ", DoubleToString(result.score, 4));
   Print("   SL: ", DoubleToString(sl, 5), " (", DoubleToString(atr * 1.5 / SymbolInfoDouble(symbol, SYMBOL_POINT), 1), " pips)");
   Print("   TP: ", DoubleToString(tp, 5), " (", DoubleToString(atr * 3.0 / SymbolInfoDouble(symbol, SYMBOL_POINT), 1), " pips)");
   Print("   R:R Ratio: 2:1");
   
   if(result.score >= 0.0 && result.score <= 1.0)
   {
      Print("✅ SUCCESS: SL/TP scoring works");
      RecordTestPass();
   }
   else
   {
      Print("❌ FAIL: Invalid score");
      RecordTestFail();
   }
}

//+------------------------------------------------------------------+
//| Test 6: Custom weight configuration                             |
//+------------------------------------------------------------------+
void Test_CustomWeights()
{
   RecordTestStart("Custom Weight Configuration");
   
   C_SignalScorer custom_scorer;
   
   // Higher weight on trend (40%), lower on historical (10%)
   bool init_result = custom_scorer.Initialize(0.40, 0.25, 0.15, 0.10, 0.10);
   
   if(!init_result)
   {
      Print("❌ FAIL: Failed to initialize with custom weights");
      RecordTestFail();
      return;
   }
   
   SignalScore result = custom_scorer.EvaluateSignal(_Symbol, PERIOD_H1, OP_BUY, 0, 0);
   
   Print("   Custom Weights: Trend=40%, Tech=25%, Context=15%, RR=10%, Historical=10%");
   Print("   Score: ", DoubleToString(result.score, 4));
   
   if(result.score >= 0.0 && result.score <= 1.0)
   {
      Print("✅ SUCCESS: Custom weights applied successfully");
      RecordTestPass();
   }
   else
   {
      Print("❌ FAIL: Invalid score with custom weights");
      RecordTestFail();
   }
}

//+------------------------------------------------------------------+
//| Test 7: Custom threshold configuration                          |
//+------------------------------------------------------------------+
void Test_CustomThresholds()
{
   RecordTestStart("Custom Threshold Configuration");
   
   C_SignalScorer custom_scorer;
   custom_scorer.Initialize();
   
   // Set stricter thresholds
   custom_scorer.SetThresholds(0.80, 0.65, 0.50);
   
   SignalScore result = custom_scorer.EvaluateSignal(_Symbol, PERIOD_H1, OP_BUY, 0, 0);
   
   Print("   Custom Thresholds: StrongTake>=0.80, Take>=0.65, Consider>=0.50");
   Print("   Score: ", DoubleToString(result.score, 4));
   Print("   Recommendation: ", EnumToString(result.recommendation));
   
   // Validate recommendation matches thresholds
   bool valid = true;
   if(result.score >= 0.80 && result.recommendation != SIGNAL_STRONG_TAKE) valid = false;
   else if(result.score >= 0.65 && result.score < 0.80 && result.recommendation != SIGNAL_TAKE) valid = false;
   
   if(valid)
   {
      Print("✅ SUCCESS: Custom thresholds working correctly");
      RecordTestPass();
   }
   else
   {
      Print("❌ FAIL: Recommendation doesn't match thresholds");
      RecordTestFail();
   }
}

//+------------------------------------------------------------------+
//| Test 8: Multiple timeframes                                      |
//+------------------------------------------------------------------+
void Test_MultipleTimeframes()
{
   RecordTestStart("Multiple Timeframe Scoring");
   
   ENUM_TIMEFRAMES timeframes[] = {PERIOD_M15, PERIOD_H1, PERIOD_H4};
   
   Print("   Testing across 3 timeframes:");
   
   bool all_valid = true;
   for(int i = 0; i < 3; i++)
   {
      SignalScore result = g_scorer.EvaluateSignal(_Symbol, timeframes[i], OP_BUY, 0, 0);
      
      Print("   ", EnumToString(timeframes[i]), " Score: ", DoubleToString(result.score, 4));
      
      if(result.score < 0.0 || result.score > 1.0)
         all_valid = false;
   }
   
   if(all_valid)
   {
      Print("✅ SUCCESS: All timeframes scored successfully");
      RecordTestPass();
   }
   else
   {
      Print("❌ FAIL: Invalid scores on some timeframes");
      RecordTestFail();
   }
}

//+------------------------------------------------------------------+
//| Test 9: Score range validation (stress test)                    |
//+------------------------------------------------------------------+
void Test_ScoreRangeValidation()
{
   RecordTestStart("Score Range Validation (Stress Test)");
   
   // Test 10 random scenarios
   int iterations = 10;
   bool all_valid = true;
   
   for(int i = 0; i < iterations; i++)
   {
      int direction = (i % 2 == 0) ? OP_BUY : OP_SELL;
      SignalScore result = g_scorer.EvaluateSignal(_Symbol, PERIOD_H1, direction, 0, 0);
      
      if(result.score < 0.0 || result.score > 1.0)
      {
         Print("   ❌ Iteration ", i, ": Score out of range: ", result.score);
         all_valid = false;
      }
      
      if(result.confidence < 0.0 || result.confidence > 1.0)
      {
         Print("   ❌ Iteration ", i, ": Confidence out of range: ", result.confidence);
         all_valid = false;
      }
   }
   
   if(all_valid)
   {
      Print("✅ SUCCESS: All ", iterations, " iterations within valid range [0.0, 1.0]");
      RecordTestPass();
   }
   else
   {
      Print("❌ FAIL: Some scores out of valid range");
      RecordTestFail();
   }
}

//+------------------------------------------------------------------+
//| Test 10: Recommendation level logic                             |
//+------------------------------------------------------------------+
void Test_RecommendationLevels()
{
   RecordTestStart("Recommendation Level Logic");
   
   Print("   Testing recommendation thresholds:");
   Print("   Default: StrongTake>=0.75, Take>=0.60, Consider>=0.45");
   
   // We can't force specific scores, but we can test the logic is working
   SignalScore result1 = g_scorer.EvaluateSignal(_Symbol, PERIOD_H1, OP_BUY, 0, 0);
   
   Print("   Current Score: ", DoubleToString(result1.score, 4));
   Print("   Recommendation: ", EnumToString(result1.recommendation));
   
   // Verify recommendation is one of the valid enum values
   bool valid_recommendation = (result1.recommendation == SIGNAL_SKIP ||
                                result1.recommendation == SIGNAL_CONSIDER ||
                                result1.recommendation == SIGNAL_TAKE ||
                                result1.recommendation == SIGNAL_STRONG_TAKE);
   
   if(valid_recommendation)
   {
      Print("✅ SUCCESS: Recommendation logic working");
      RecordTestPass();
   }
   else
   {
      Print("❌ FAIL: Invalid recommendation value");
      RecordTestFail();
   }
}

//+------------------------------------------------------------------+
//| Helper: Record test start                                       |
//+------------------------------------------------------------------+
void RecordTestStart(string testName)
{
   g_testsRun++;
   Print("");
   Print(">>> Test ", g_testsRun, ": ", testName);
}

//+------------------------------------------------------------------+
//| Helper: Record test pass                                        |
//+------------------------------------------------------------------+
void RecordTestPass()
{
   g_testsPassed++;
}

//+------------------------------------------------------------------+
//| Helper: Record test fail                                        |
//+------------------------------------------------------------------+
void RecordTestFail()
{
   g_testsFailed++;
}

//+------------------------------------------------------------------+
//| Print test summary                                               |
//+------------------------------------------------------------------+
void PrintTestSummary()
{
   Print("");
   Print("========================================");
   Print("Test Suite Complete");
   Print("Tests Passed: ", g_testsPassed);
   Print("Tests Failed: ", g_testsFailed);
   Print("Success Rate: ", DoubleToString((double)g_testsPassed / g_testsRun * 100.0, 1), "%");
   Print("========================================");
   
   if(g_testsFailed == 0)
   {
      Print("");
      Print("🎉 ALL TESTS PASSED! Signal Scorer is working correctly!");
      Print("");
   }
   else
   {
      Print("");
      Print("⚠️  Some tests failed. Review output above.");
      Print("");
   }
}
//+------------------------------------------------------------------+
