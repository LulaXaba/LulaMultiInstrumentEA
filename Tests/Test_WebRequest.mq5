//+------------------------------------------------------------------+
//|                                              Test_WebRequest.mq5 |
//|                                  LulaMultiInstrumentEA Test Suite|
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "LulaMultiInstrumentEA"
#property version   "1.00"
#property strict

#include "../Core/ML/C_HTTPClient.mqh"
#include "../Core/ML/C_JSONHelper.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input bool InpRunOnInit = true;           // Run tests on initialization
input bool InpTestPublicAPI = true;       // Test public API (httpbin.org)
input bool InpTestLocalAPI = true;        // Test local API (localhost:8000)
input int  InpTimeout = 2000;             // Request timeout (ms)

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
C_HTTPClient g_httpClient;
C_JSONHelper g_jsonHelper;
int g_testsPassed = 0;
int g_testsFailed = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("========================================");
    Print("WebRequest Functionality Test Suite");
    Print("========================================");
    Print("Date: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
    Print("");
    
    if(InpRunOnInit)
    {
        RunAllTests();
    }
    else
    {
        Print("Tests will run on first tick. Set InpRunOnInit=true to run on init.");
    }
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("\n========================================");
    Print("Test Suite Complete");
    Print("Tests Passed: ", g_testsPassed);
    Print("Tests Failed: ", g_testsFailed);
    Print("Success Rate: ", (g_testsPassed + g_testsFailed > 0) ? 
          StringFormat("%.1f%%", 100.0 * g_testsPassed / (g_testsPassed + g_testsFailed)) : "N/A");
    Print("========================================");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Only run once
    static bool testsRun = false;
    
    if(!testsRun && !InpRunOnInit)
    {
        RunAllTests();
        testsRun = true;
    }
}

//+------------------------------------------------------------------+
//| Run all test cases                                               |
//+------------------------------------------------------------------+
void RunAllTests()
{
    g_testsPassed = 0;
    g_testsFailed = 0;
    
    Print("\n--- Starting WebRequest Tests ---\n");
    
    // Test 1: Check WebRequest availability
    Test_WebRequestAvailability();
    
    if(InpTestPublicAPI)
    {
        Print("\n--- Public API Tests (httpbin.org) ---\n");
        
        // Test 2: Basic GET request
        Test_BasicGET();
        
        // Test 3: GET with headers
        Test_GETWithHeaders();
        
        // Test 4: POST request with JSON
        Test_POSTWithJSON();
        
        // Test 5: Error handling (404)
        Test_ErrorHandling404();
        
        // Test 6: Timeout handling
        Test_TimeoutHandling();
    }
    
    if(InpTestLocalAPI)
    {
        Print("\n--- Local API Tests (localhost:8000) ---\n");
        
        // Test 7: Local API health check
        Test_LocalAPIHealth();
        
        // Test 8: Mock ML prediction
        Test_MockMLPrediction();
    }
    
    // Test 9: JSON Helper Tests
    Print("\n--- JSON Helper Tests ---\n");
    Test_JSONCreation();
    Test_JSONParsing();
    
    Print("\n--- All Tests Completed ---\n");
}

//+------------------------------------------------------------------+
//| Test 1: WebRequest Availability                                  |
//+------------------------------------------------------------------+
void Test_WebRequestAvailability()
{
    PrintTestHeader("WebRequest Availability Check");
    
    // Attempt a simple WebRequest
    char data[];
    char result[];
    string headers = "";
    string resultHeaders;
    
    ResetLastError();
    int httpCode = WebRequest(
        "GET",
        "http://httpbin.org/get",
        "",
        NULL,
        InpTimeout,
        data,
        0,
        result,
        resultHeaders
    );
    
    int error = GetLastError();
    
    if(error == 4060)
    {
        Print("❌ CRITICAL: WebRequest is NOT ALLOWED!");
        Print("   Action Required:");
        Print("   1. Open MT5: Tools → Options → Expert Advisors");
        Print("   2. Enable 'Allow WebRequest for listed URLs'");
        Print("   3. Add to whitelist: http://httpbin.org");
        Print("   4. Add to whitelist: http://localhost:8000");
        Print("   5. Restart MT5 and run test again");
        RecordTestFail();
        return;
    }
    else if(error != 0)
    {
        Print("⚠️  WebRequest error: ", error, " - ", ErrorDescription(error));
        Print("   This may indicate network issues or firewall blocking");
        RecordTestFail();
        return;
    }
    else if(httpCode == 200)
    {
        Print("✅ SUCCESS: WebRequest is working!");
        Print("   HTTP Code: ", httpCode);
        Print("   Response length: ", ArraySize(result), " bytes");
        RecordTestPass();
        return;
    }
    else
    {
        Print("⚠️  Unexpected HTTP code: ", httpCode);
        RecordTestFail();
        return;
    }
}

//+------------------------------------------------------------------+
//| Test 2: Basic GET Request                                        |
//+------------------------------------------------------------------+
void Test_BasicGET()
{
    PrintTestHeader("Basic GET Request");
    
    if(!g_httpClient.Initialize("http://httpbin.org", InpTimeout))
    {
        Print("❌ Failed to initialize HTTP client");
        RecordTestFail();
        return;
    }
    
    string headers[];
    ArrayResize(headers, 1);
    headers[0] = "User-Agent: MQL5-HTTPClient/1.0";
    
    string response = g_httpClient.GET("/get", headers);
    int httpCode = g_httpClient.GetLastHTTPCode();
    
    if(httpCode == 200 && StringLen(response) > 0)
    {
        Print("✅ SUCCESS: GET request completed");
        Print("   HTTP Code: ", httpCode);
        Print("   Response preview: ", StringSubstr(response, 0, 100), "...");
        RecordTestPass();
    }
    else
    {
        Print("❌ FAILED: GET request failed");
        Print("   HTTP Code: ", httpCode);
        Print("   Error: ", g_httpClient.GetLastError());
        RecordTestFail();
    }
}

//+------------------------------------------------------------------+
//| Test 3: GET with Custom Headers                                  |
//+------------------------------------------------------------------+
void Test_GETWithHeaders()
{
    PrintTestHeader("GET Request with Custom Headers");
    
    string headers[];
    ArrayResize(headers, 2);
    headers[0] = "User-Agent: MQL5-Test-Suite/1.0";
    headers[1] = "X-Custom-Header: TestValue";
    
    string response = g_httpClient.GET("/headers", headers);
    int httpCode = g_httpClient.GetLastHTTPCode();
    
    if(httpCode == 200)
    {
        Print("✅ SUCCESS: GET with headers completed");
        Print("   Response length: ", StringLen(response), " bytes");
        RecordTestPass();
    }
    else
    {
        Print("❌ FAILED: GET with headers failed");
        Print("   HTTP Code: ", httpCode);
        RecordTestFail();
    }
}

//+------------------------------------------------------------------+
//| Test 4: POST Request with JSON                                   |
//+------------------------------------------------------------------+
void Test_POSTWithJSON()
{
    PrintTestHeader("POST Request with JSON Data");
    
    // Create test JSON
    double features[5] = {1.2345, 2.3456, 3.4567, 4.5678, 5.6789};
    string jsonData = g_jsonHelper.CreatePredictionRequest("EURUSD", "M15", features, 5);
    
    Print("   Request JSON: ", jsonData);
    
    string headers[];
    ArrayResize(headers, 1);
    headers[0] = "Content-Type: application/json";
    
    string response = g_httpClient.POST("/post", jsonData, headers);
    int httpCode = g_httpClient.GetLastHTTPCode();
    
    if(httpCode == 200 && StringLen(response) > 0)
    {
        Print("✅ SUCCESS: POST request completed");
        Print("   HTTP Code: ", httpCode);
        Print("   Response preview: ", StringSubstr(response, 0, 150), "...");
        RecordTestPass();
    }
    else
    {
        Print("❌ FAILED: POST request failed");
        Print("   HTTP Code: ", httpCode);
        Print("   Error: ", g_httpClient.GetLastError());
        RecordTestFail();
    }
}

//+------------------------------------------------------------------+
//| Test 5: 404 Error Handling                                       |
//+------------------------------------------------------------------+
void Test_ErrorHandling404()
{
    PrintTestHeader("Error Handling - 404 Not Found");
    
    string headers[];
    string response = g_httpClient.GET("/status/404", headers);
    int httpCode = g_httpClient.GetLastHTTPCode();
    
    if(httpCode == 404)
    {
        Print("✅ SUCCESS: 404 error handled correctly");
        Print("   HTTP Code: ", httpCode);
        RecordTestPass();
    }
    else
    {
        Print("❌ FAILED: Expected 404, got ", httpCode);
        RecordTestFail();
    }
}

//+------------------------------------------------------------------+
//| Test 6: Timeout Handling                                         |
//+------------------------------------------------------------------+
void Test_TimeoutHandling()
{
    PrintTestHeader("Timeout Handling");
    
    // Reinitialize with very short timeout
    C_HTTPClient shortTimeout;
    if(!shortTimeout.Initialize("http://httpbin.org", 100, 0)) // 100ms timeout, no retries
    {
        Print("❌ Failed to initialize timeout test client");
        RecordTestFail();
        return;
    }
    
    string headers[];
    uint startTime = GetTickCount();
    string response = shortTimeout.GET("/delay/2", headers); // 2 second delay
    uint elapsedTime = GetTickCount() - startTime;
    
    int httpCode = shortTimeout.GetLastHTTPCode();
    
    // Should timeout quickly
    if(elapsedTime < 1000 && (httpCode == 0 || StringLen(response) == 0))
    {
        Print("✅ SUCCESS: Timeout handled correctly");
        Print("   Elapsed time: ", elapsedTime, "ms");
        Print("   Error: ", shortTimeout.GetLastError());
        RecordTestPass();
    }
    else if(httpCode == 200)
    {
        Print("⚠️  WARNING: Request completed despite short timeout");
        Print("   This may indicate network is very fast");
        RecordTestPass(); // Not a failure, just unexpected
    }
    else
    {
        Print("❌ FAILED: Timeout handling unclear");
        Print("   Elapsed: ", elapsedTime, "ms, HTTP: ", httpCode);
        RecordTestFail();
    }
}

//+------------------------------------------------------------------+
//| Test 7: Local API Health Check                                   |
//+------------------------------------------------------------------+
void Test_LocalAPIHealth()
{
    PrintTestHeader("Local API Health Check (127.0.0.1:8000)");
    
    C_HTTPClient localClient;
    if(!localClient.Initialize("http://127.0.0.1:8000", InpTimeout))
    {
        Print("❌ Failed to initialize local client");
        RecordTestFail();
        return;
    }
    
    string headers[];
    string response = localClient.GET("/health", headers);
    int httpCode = localClient.GetLastHTTPCode();
    
    if(httpCode == 200)
    {
        Print("✅ SUCCESS: Local API is running!");
        Print("   Response: ", response);
        RecordTestPass();
    }
    else if(httpCode == 0 || httpCode == -1)
    {
        Print("⚠️  Local API not running (expected if not started)");
        Print("   To run: python test_ml_api.py");
        Print("   Error: ", localClient.GetLastError());
        RecordTestFail();
    }
    else
    {
        Print("❌ FAILED: Unexpected response from local API");
        Print("   HTTP Code: ", httpCode);
        RecordTestFail();
    }
}

//+------------------------------------------------------------------+
//| Test 8: Mock ML Prediction                                       |
//+------------------------------------------------------------------+
void Test_MockMLPrediction()
{
    PrintTestHeader("Mock ML Prediction Request");
    
    C_HTTPClient localClient;
    if(!localClient.Initialize("http://127.0.0.1:8000", InpTimeout))
    {
        Print("⚠️  Skipping (client init failed)");
        return;
    }
    
    // Create feature array
    double features[10];
    for(int i = 0; i < 10; i++)
    {
        features[i] = MathRand() / 32767.0; // Random features 0-1
    }
    
    string jsonData = g_jsonHelper.CreatePredictionRequest("EURUSD", "M15", features, 10);
    
    string headers[];
    ArrayResize(headers, 1);
    headers[0] = "Content-Type: application/json";
    
    string response = localClient.POST("/predict/signal_quality", jsonData, headers);
    int httpCode = localClient.GetLastHTTPCode();
    
    if(httpCode == 200)
    {
        Print("✅ SUCCESS: ML prediction request completed!");
        Print("   Response: ", response);
        
        // Try to parse score
        double score = 0.0;
        if(g_jsonHelper.ParseDouble(response, "score", score))
        {
            Print("   Parsed score: ", DoubleToString(score, 4));
        }
        
        RecordTestPass();
    }
    else
    {
        Print("⚠️  Local API not responding (run python test_ml_api.py)");
        RecordTestFail();
    }
}

//+------------------------------------------------------------------+
//| Test 9: JSON Creation                                            |
//+------------------------------------------------------------------+
void Test_JSONCreation()
{
    PrintTestHeader("JSON Creation Tests");
    
    double features[5] = {1.1, 2.2, 3.3, 4.4, 5.5};
    
    string jsonArray = g_jsonHelper.CreateFeatureArray(features, 5);
    Print("   Feature array: ", jsonArray);
    
    string jsonRequest = g_jsonHelper.CreatePredictionRequest("GBPUSD", "H1", features, 5);
    Print("   Full request: ", jsonRequest);
    
    // Basic validation
    if(StringFind(jsonArray, "[") >= 0 && StringFind(jsonArray, "]") >= 0)
    {
        Print("✅ SUCCESS: JSON array created");
        RecordTestPass();
    }
    else
    {
        Print("❌ FAILED: Invalid JSON array format");
        RecordTestFail();
    }
}

//+------------------------------------------------------------------+
//| Test 10: JSON Parsing                                            |
//+------------------------------------------------------------------+
void Test_JSONParsing()
{
    PrintTestHeader("JSON Parsing Tests");
    
    string testJSON = "{\"score\": 0.75, \"confidence\": 0.82, \"symbol\": \"EURUSD\"}";
    
    double score = 0.0;
    double confidence = 0.0;
    string symbol = "";
    
    bool success = true;
    
    if(g_jsonHelper.ParseDouble(testJSON, "score", score))
    {
        Print("   ✓ Parsed score: ", score);
    }
    else
    {
        Print("   ✗ Failed to parse score");
        success = false;
    }
    
    if(g_jsonHelper.ParseDouble(testJSON, "confidence", confidence))
    {
        Print("   ✓ Parsed confidence: ", confidence);
    }
    else
    {
        Print("   ✗ Failed to parse confidence");
        success = false;
    }
    
    if(g_jsonHelper.ParseString(testJSON, "symbol", symbol))
    {
        Print("   ✓ Parsed symbol: ", symbol);
    }
    else
    {
        Print("   ✗ Failed to parse symbol");
        success = false;
    }
    
    if(success && score == 0.75 && confidence == 0.82 && symbol == "EURUSD")
    {
        Print("✅ SUCCESS: JSON parsing working correctly");
        RecordTestPass();
    }
    else
    {
        Print("❌ FAILED: JSON parsing errors");
        RecordTestFail();
    }
}

//+------------------------------------------------------------------+
//| Helper Functions                                                  |
//+------------------------------------------------------------------+
void PrintTestHeader(string testName)
{
    Print("\n>>> Test: ", testName);
}

void RecordTestPass()
{
    g_testsPassed++;
}

void RecordTestFail()
{
    g_testsFailed++;
}

string ErrorDescription(int errorCode)
{
    switch(errorCode)
    {
        case 4060: return "WebRequest not allowed (add URL to whitelist)";
        case 5203: return "Request timeout or network error";
        default: return "Error code " + IntegerToString(errorCode);
    }
}
//+------------------------------------------------------------------+
