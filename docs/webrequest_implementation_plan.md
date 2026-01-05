# WebRequest Setup & Testing - Implementation Plan

## Goal

Validate that the MT5 broker allows WebRequest functionality, which is **critical** for the Python ML API integration approach. This is a **blocking validation** that must pass before proceeding with Phase 1 of the ML/AI integration plan.

## User Review Required

> [!IMPORTANT]
> **Critical Validation Step**
> - This test determines if the entire Python ML API approach is feasible
> - If WebRequest is blocked by broker, we need to choose an alternative path:
>   - Switch to a broker that allows WebRequest
>   - Implement C++ DLL with ONNX (much more complex)
>   - Stick with ML-Lite only (no external API)

> [!WARNING]
> **Broker Compatibility**
> - Many brokers block WebRequest for security reasons
> - MT5 requires manual URL whitelisting in settings
> - Error code 4060 indicates WebRequest is disabled/blocked
> - This must work for Phase 1 (True ML Integration) to proceed

## Proposed Changes

### Component 1: WebRequest Test Infrastructure

#### [NEW] [Test_WebRequest.mq5](file:///c:/Users/Admin/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/Experts/Advisors/LulaMultiInstrumentEA/Tests/Test_WebRequest.mq5)

**Purpose**: Simple test EA to validate WebRequest functionality

**Features**:
- Test basic GET request to `http://httpbin.org/get`
- Test POST request with JSON data
- Test timeout handling
- Test error codes and messages
- Comprehensive logging of results

**Expected Behavior**:
- Success: HTTP 200 response with JSON data
- Failure: Error 4060 (WebRequest not allowed) or other error codes

---

#### [NEW] [ML/C_HTTPClient.mqh](file:///c:/Users/Admin/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/Experts/Advisors/LulaMultiInstrumentEA/Core/ML/C_HTTPClient.mqh)

**Purpose**: HTTP client wrapper for WebRequest with error handling

**Features**:
- `GET()` and `POST()` methods
- JSON request/response handling
- Timeout configuration
- Retry logic
- Error handling and logging
- Health check functionality

**Methods**:
```cpp
class C_HTTPClient {
public:
    bool Initialize(string baseUrl, int timeout_ms);
    string GET(string endpoint, string &headers[]);
    string POST(string endpoint, string jsonBody, string &headers[]);
    bool IsHealthy();
    int GetLastHTTPCode();
    string GetLastError();
};
```

---

#### [NEW] [ML/C_JSONHelper.mqh](file:///c:/Users/Admin/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/Experts/Advisors/LulaMultiInstrumentEA/Core/ML/C_JSONHelper.mqh)

**Purpose**: JSON serialization/deserialization helper

**Features**:
- Create JSON request strings
- Parse JSON responses
- Handle arrays and nested objects
- Type-safe value extraction

**Note**: MQL5 doesn't have native JSON library, so we'll use string formatting or simple parsing

---

### Component 2: Broker Configuration Guide

#### Documentation: MT5 WebRequest Setup

**Steps to Enable WebRequest**:

1. Open MT5 Terminal
2. Go to: **Tools → Options → Expert Advisors**
3. Check: **"Allow WebRequest for listed URLs"**
4. Add test URLs:
   - `http://httpbin.org`
   - `http://localhost:8000` (for future local API testing)
   - Your future production ML API URL
5. Click OK and restart MT5

**Common Issues**:
- Broker policy blocks all WebRequest → Switch broker
- Firewall blocking outbound HTTP → Configure firewall
- URL not whitelisted → Add to list
- HTTPS certificate issues → Use HTTP for testing, HTTPS for production

---

### Component 3: Test Scenarios

#### Test 1: Basic Connectivity
**Purpose**: Verify WebRequest works at all

**Steps**:
1. Compile and run `Test_WebRequest.mq5`
2. Test public API: `http://httpbin.org/get`
3. Check response and HTTP code
4. Verify no error 4060

**Success Criteria**: 
- HTTP 200 response received
- JSON data parsed correctly
- No WebRequest errors

---

#### Test 2: POST Request with Data
**Purpose**: Verify we can send data to API

**Steps**:
1. POST JSON to `http://httpbin.org/post`
2. Include test feature array
3. Verify echo response

**Success Criteria**:
- POST succeeds
- JSON properly formatted
- Response matches sent data

---

#### Test 3: Timeout Handling
**Purpose**: Verify timeout protection works

**Steps**:
1. Set short timeout (100ms)
2. Call slow endpoint
3. Verify timeout error caught

**Success Criteria**:
- Timeout error detected
- EA doesn't hang
- Error logged properly

---

#### Test 4: Error Scenarios
**Purpose**: Test error handling

**Test Cases**:
- Invalid URL (404)
- Malformed JSON
- Network failure
- Server error (500)

**Success Criteria**:
- All errors caught gracefully
- Appropriate error messages
- EA remains stable

---

### Component 4: ML API Mock Server (Python)

#### [NEW] Python Test Server

**Purpose**: Simple FastAPI server for integration testing

**File**: `test_ml_api.py`

```python
from fastapi import FastAPI
import uvicorn

app = FastAPI()

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "ML API Test Server"}

@app.post("/predict/signal_quality")
def predict_signal(data: dict):
    # Mock prediction
    return {
        "score": 0.75,
        "confidence": 0.82,
        "latency_ms": 15
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

**Usage**:
```bash
python test_ml_api.py
```

---

## Verification Plan

### Phase 1: Environment Setup

#### 1. Install Dependencies
**Steps**:
```bash
# Python environment
python -m pip install fastapi uvicorn requests

# Verify installation
python -c "import fastapi; print('FastAPI OK')"
```

**Success Criteria**: All packages installed without errors

---

#### 2. Configure MT5
**Steps**:
1. Open MT5 settings
2. Enable WebRequest
3. Add whitelist URLs
4. Restart terminal

**Success Criteria**: URLs appear in whitelist, no errors

---

### Phase 2: Basic Testing

#### 3. Test Public API
**Steps**:
1. Compile `Test_WebRequest.mq5`
2. Attach to chart
3. Check Experts log

**Expected Log Output**:
```
2026.01.01 03:10:00 Test_WebRequest EURUSD,M15: Starting WebRequest tests...
2026.01.01 03:10:00 Test_WebRequest EURUSD,M15: Test 1: GET request to httpbin.org
2026.01.01 03:10:01 Test_WebRequest EURUSD,M15: ✓ SUCCESS - HTTP 200, Response length: 312 bytes
2026.01.01 03:10:01 Test_WebRequest EURUSD,M15: Test 2: POST request with JSON
2026.01.01 03:10:02 Test_WebRequest EURUSD,M15: ✓ SUCCESS - HTTP 200, JSON echoed correctly
2026.01.01 03:10:02 Test_WebRequest EURUSD,M15: All tests PASSED - WebRequest is functional!
```

**Success Criteria**: All tests pass, no error 4060

---

#### 4. Test Local API
**Steps**:
1. Start Python test server: `python test_ml_api.py`
2. Verify server running: `http://localhost:8000/docs`
3. Run MQL5 test against localhost
4. Verify request/response cycle

**Success Criteria**: 
- MQL5 successfully calls local server
- JSON request/response working
- Latency < 50ms

---

### Phase 3: Performance Testing

#### 5. Latency Measurement
**Test**: Measure average API call time

**Steps**:
1. Make 100 sequential requests
2. Record min/max/avg latency
3. Calculate 95th percentile

**Success Criteria**:
- Average latency < 50ms
- 95th percentile < 100ms
- No timeouts or failures

---

#### 6. Stress Testing
**Test**: Verify stability under load

**Steps**:
1. Make rapid sequential calls (1000 requests)
2. Monitor memory usage
3. Check for errors or crashes

**Success Criteria**:
- No errors
- No memory leaks
- EA remains stable

---

### Phase 4: Integration Testing

#### 7. Mock ML Prediction Flow
**Test**: End-to-end test of ML prediction workflow

**Steps**:
1. Extract features from market data
2. Send to API as JSON
3. Receive prediction
4. Parse and use result
5. Log full cycle time

**Success Criteria**:
- Complete cycle < 100ms
- Prediction data valid
- No errors in parsing

---

## Risk Mitigation

> [!CAUTION]
> **Potential Blockers**
> - **Broker blocks WebRequest** → Showstopper, need alternative approach
> - **Firewall/antivirus interference** → May need configuration changes  
> - **Network latency too high** → Consider VPS hosting closer to broker server
> - **MT5 version too old** → Update to latest build

**Contingency Plans**:

If WebRequest blocked:
1. **Option A**: Switch to broker that allows WebRequest (recommended)
2. **Option B**: Use C++ DLL approach (complex, requires C++ development)
3. **Option C**: ML-Lite only, no external API (simpler but limited)

If latency too high (> 200ms):
1. Use caching for predictions
2. Call API asynchronously
3. Host ML server on VPS near broker

---

## Implementation Checklist

### Week 1: Setup & Basic Testing
- [ ] Create `ML` folder structure
- [ ] Implement `C_HTTPClient.mqh`
- [ ] Implement `C_JSONHelper.mqh`
- [ ] Create `Test_WebRequest.mq5`
- [ ] Configure MT5 WebRequest whitelist
- [ ] Test public API (httpbin.org)

### Week 1-2: Python Test Server
- [ ] Install Python dependencies
- [ ] Create FastAPI test server
- [ ] Implement health check endpoint
- [ ] Implement mock prediction endpoint
- [ ] Test locally in browser

### Week 2: Integration Testing
- [ ] Test MQL5 → Python communication
- [ ] Measure latency
- [ ] Test error scenarios
- [ ] Validate JSON format
- [ ] Document any issues

### Week 2: Decision Point
- [ ] ✅ WebRequest works → Proceed to Phase 0 (ML-Lite)
- [ ] ❌ WebRequest blocked → Discuss alternatives

---

## Next Steps After Validation

**If WebRequest Works** ✅:
1. Proceed to Phase 0: ML-Lite Foundation
2. Implement `C_SignalScorer.mqh` (rule-based)
3. Implement `C_DataCollector.mqh`
4. Collect training data
5. Prepare for Phase 1 (True ML)

**If WebRequest Blocked** ❌:
1. Investigate broker policy
2. Consider broker switch
3. Evaluate alternative approaches
4. Possibly stick with ML-Lite only

---

## Technical Notes

### MQL5 WebRequest Limitations

- **Max response size**: 5 MB
- **Timeout range**: 100ms - 5000ms
- **Synchronous only**: Blocks EA thread during call
- **HTTPS**: Requires trusted certificate
- **Whitelist**: URLs must be pre-approved
- **No cookies**: Session management requires custom headers

### Performance Considerations

- Each WebRequest call is blocking (synchronous)
- Typical latency: 30-150ms (local server) or 100-500ms (cloud)
- For real-time trading, aim for < 100ms total
- Consider calling API only once per bar, not per tick

---

## Success Criteria Summary

This test phase is **successful** if:

1. ✅ WebRequest enabled in MT5 without errors
2. ✅ Public API test (httpbin.org) returns HTTP 200
3. ✅ POST requests work with JSON data
4. ✅ Local Python server communication successful
5. ✅ Average latency < 50ms (local) or < 200ms (cloud)
6. ✅ Error handling works correctly
7. ✅ No blocking issues or crashes

**Failure condition**: Error 4060 (WebRequest not allowed) → Requires alternative approach

---

## Questions for User

Before implementation:

1. **Broker name**: Which broker are you using? (To check WebRequest policy)
2. **Network**: Are you on corporate network with firewall? (May block external calls)
3. **Python**: Do you have Python 3.8+ installed?
4. **Hosting preference**: Local testing OK, or need cloud server immediately?

Let me know when you're ready to proceed with implementation!
