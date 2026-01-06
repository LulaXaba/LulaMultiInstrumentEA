//+------------------------------------------------------------------+
//|                                    Test_PerformanceTracker.mq5   |
//|                         Performance Tracker Test Suite           |
//+------------------------------------------------------------------+
#property copyright "LulaXaba"
#property link      "https://github.com/LulaXaba/LulaMultiInstrumentEA"
#property version   "1.00"
#property strict

#include "../Core/ML/C_PerformanceTracker.mqh"

// Global test object
C_PerformanceTracker g_tracker;

// Test counters
int g_testsPassed = 0;
int g_testsFailed = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("========================================");
   Print("Performance Tracker Test Suite");
   Print("========================================");
   
   // Initialize tracker
   if(!g_tracker.Initialize())
   {
      Print("❌ Failed to initialize performance tracker");
      return INIT_FAILED;
   }
   
   Print("✅ Performance tracker initialized");
   Print("");
   
   // Run tests
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
   g_tracker.Shutdown();
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
void RunAllTests()
{
   Print("=== Test 1: Record High Score Signals ===");
   TestHighScoreSignals();
   Print("");
   
   Print("=== Test 2: Record Medium Score Signals ===");
   TestMediumScoreSignals();
   Print("");
   
   Print("=== Test 3: Record Low Score Signals ===");
   TestLowScoreSignals();
   Print("");
   
   Print("=== Test 4: Record Trade Outcomes ===");
   TestTradeOutcomes();
   Print("");
   
   Print("=== Test 5: Metrics Calculation ===");
   TestMetricsCalculation();
   Print("");
   
   Print("=== Test 6: Calibration Check ===");
   TestCalibration();
   Print("");
   
   Print("=== Test 7: Dashboard Generation ===");
   TestDashboard();
   Print("");
}

//+------------------------------------------------------------------+
//| Test 1: Record high score signals                               |
//+------------------------------------------------------------------+
void TestHighScoreSignals()
{
   string testName = "High Score Signals";
   
   // Record 10 high-score signals (5 taken, 5 skipped)
   for(int i = 0; i < 10; i++)
   {
      double score = 0.75 + (i * 0.01); // 0.75 to 0.84
      bool taken = (i % 2 == 0);
      g_tracker.RecordSignal(score, taken);
   }
   
   TierMetrics highTier = g_tracker.GetHighTierMetrics();
   
   if(highTier.signalsGenerated == 10 && 
      highTier.signalsTaken == 5 && 
      highTier.signalsSkipped == 5)
   {
      Print("✅ PASS: ", testName);
      g_testsPassed++;
   }
   else
   {
      Print("❌ FAIL: ", testName);
      PrintFormat("  Expected: 10 gen, 5 taken, 5 skipped");
      PrintFormat("  Got: %d gen, %d taken, %d skipped", 
                  highTier.signalsGenerated, 
                  highTier.signalsTaken,
                  highTier.signalsSkipped);
      g_testsFailed++;
   }
}

//+------------------------------------------------------------------+
//| Test 2: Record medium score signals                             |
//+------------------------------------------------------------------+
void TestMediumScoreSignals()
{
   string testName = "Medium Score Signals";
   
   // Record 15 medium-score signals
   for(int i = 0; i < 15; i++)
   {
      double score = 0.55 + (i * 0.005); // 0.55 to 0.625
      bool taken = (i < 10);
      g_tracker.RecordSignal(score, taken);
   }
   
   TierMetrics medTier = g_tracker.GetMediumTierMetrics();
   
   if(medTier.signalsGenerated == 15 && 
      medTier.signalsTaken == 10 && 
      medTier.signalsSkipped == 5)
   {
      Print("✅ PASS: ", testName);
      g_testsPassed++;
   }
   else
   {
      Print("❌ FAIL: ", testName);
      g_testsFailed++;
   }
}

//+------------------------------------------------------------------+
//| Test 3: Record low score signals                                |
//+------------------------------------------------------------------+
void TestLowScoreSignals()
{
   string testName = "Low Score Signals";
   
   // Record 5 low-score signals (all skipped)
   for(int i = 0; i < 5; i++)
   {
      double score = 0.30 + (i * 0.02);
      g_tracker.RecordSignal(score, false);
   }
   
   TierMetrics lowTier = g_tracker.GetLowTierMetrics();
   
   if(lowTier.signalsGenerated == 5 && 
      lowTier.signalsTaken == 0 && 
      lowTier.signalsSkipped == 5)
   {
      Print("✅ PASS: ", testName);
      g_testsPassed++;
   }
   else
   {
      Print("❌ FAIL: ", testName);
      g_testsFailed++;
   }
}

//+------------------------------------------------------------------+
//| Test 4: Record trade outcomes                                   |
//+------------------------------------------------------------------+
void TestTradeOutcomes()
{
   string testName = "Trade Outcomes";
   
   // Record high-score wins (4 wins, 1 loss)
   g_tracker.RecordOutcome(0.80, true, 45.2);
   g_tracker.RecordOutcome(0.75, true, 32.1);
   g_tracker.RecordOutcome(0.78, true, 28.5);
   g_tracker.RecordOutcome(0.82, true, 51.3);
   g_tracker.RecordOutcome(0.76, false, -18.5);
   
   // Record medium-score mixed (3 wins, 2 losses)
   g_tracker.RecordOutcome(0.62, true, 22.0);
   g_tracker.RecordOutcome(0.58, false, -25.0);
   g_tracker.RecordOutcome(0.65, true, 18.5);
   g_tracker.RecordOutcome(0.60, false, -22.3);
   g_tracker.RecordOutcome(0.59, true, 15.2);
   
   TierMetrics highTier = g_tracker.GetHighTierMetrics();
   TierMetrics medTier = g_tracker.GetMediumTierMetrics();
   
   bool highOK = (highTier.wins == 4 && highTier.losses == 1);
   bool medOK = (medTier.wins == 3 && medTier.losses == 2);
   
   if(highOK && medOK)
   {
      Print("✅ PASS: ", testName);
      PrintFormat("  High tier: 4W/1L, Med tier: 3W/2L");
      g_testsPassed++;
   }
   else
   {
      Print("❌ FAIL: ", testName);
      PrintFormat("  High tier: %dW/%dL, Med tier: %dW/%dL",
                  highTier.wins, highTier.losses,
                  medTier.wins, medTier.losses);
      g_testsFailed++;
   }
}

//+------------------------------------------------------------------+
//| Test 5: Metrics calculation                                     |
//+------------------------------------------------------------------+
void TestMetricsCalculation()
{
   string testName = "Metrics Calculation";
   
   TierMetrics highTier = g_tracker.GetHighTierMetrics();
   
   // High tier should have 80% win rate (4W/1L)
   double expectedWR = 0.80;
   bool wrOK = (MathAbs(highTier.winRate - expectedWR) < 0.01);
   
   // Should have positive expectancy
   bool expectOK = (highTier.expectancy > 0);
   
   // Should have profit factor > 1
   bool pfOK = (highTier.profitFactor > 1.0);
   
   if(wr OK && expectOK && pfOK)
   {
      Print("✅ PASS: ", testName);
      PrintFormat("  Win Rate: %.1f%%, PF: %.2f, Expectancy: %.1f", 
                  highTier.winRate * 100.0,
                  highTier.profitFactor,
                  highTier.expectancy);
      g_testsPassed++;
   }
   else
   {
      Print("❌ FAIL: ", testName);
      g_testsFailed++;
   }
}

//+------------------------------------------------------------------+
//| Test 6: Calibration check                                       |
//+------------------------------------------------------------------+
void TestCalibration()
{
   string testName = "Calibration Check";
   
   bool calibrated = g_tracker.IsScoreCalibrated();
   double calibScore = g_tracker.GetCalibrationScore();
   
   TierMetrics highTier = g_tracker.GetHighTierMetrics();
   TierMetrics medTier = g_tracker.GetMediumTierMetrics();
   
   // High tier should have better win rate than medium
   bool highWins = (highTier.winRate > medTier.winRate);
   
   if(calibrated && highWins && calibScore > 0)
   {
      Print("✅ PASS: ", testName);
      PrintFormat("  Calibrated: YES, Score: %.1f%%", calibScore);
      PrintFormat("  High WR: %.1f%%, Med WR: %.1f%%",
                  highTier.winRate * 100.0,
                  medTier.winRate * 100.0);
      g_testsPassed++;
   }
   else
   {
      Print("❌ FAIL: ", testName);
      g_testsFailed++;
   }
}

//+------------------------------------------------------------------+
//| Test 7: Dashboard generation                                    |
//+------------------------------------------------------------------+
void TestDashboard()
{
   string testName = "Dashboard Generation";
   
   string dashboard = g_tracker.GenerateDashboard(7);
   
   bool hasHeader = (StringFind(dashboard, "ML-LITE PERFORMANCE DASHBOARD") >= 0);
   bool hasTiers = (StringFind(dashboard, "HIGH TIER") >= 0);
   bool hasOverall = (StringFind(dashboard, "OVERALL PERFORMANCE") >= 0);
   bool hasCalib = (StringFind(dashboard, "CALIBRATION CHECK") >= 0);
   
   if(hasHeader && hasTiers && hasOverall && hasCalib && StringLen(dashboard) > 100)
   {
      Print("✅ PASS: ", testName);
      Print("  Dashboard length: ", StringLen(dashboard), " chars");
      Print("");
      Print("--- DASHBOARD OUTPUT ---");
      Print(dashboard);
      g_testsPassed++;
   }
   else
   {
      Print("❌ FAIL: ", testName);
      g_testsFailed++;
   }
}

//+------------------------------------------------------------------+
//| Print test summary                                               |
//+------------------------------------------------------------------+
void PrintTestSummary()
{
   Print("========================================");
   Print("Test Suite Complete");
   Print("========================================");
   PrintFormat("Tests Passed: %d", g_testsPassed);
   PrintFormat("Tests Failed: %d", g_testsFailed);
   PrintFormat("Success Rate: %.1f%%", 
               (double)g_testsPassed / (double)(g_testsPassed + g_testsFailed) * 100.0);
   Print("========================================");
}
//+------------------------------------------------------------------+
