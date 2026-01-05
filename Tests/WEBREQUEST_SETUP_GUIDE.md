# WebRequest Setup & Testing Guide

## 🎯 Purpose

This guide walks you through testing WebRequest functionality in MT5, which is **critical** for the ML/AI integration. If WebRequest doesn't work, the entire Python ML API approach won't be feasible.

## ⚠️ Why This Matters

The ML/AI integration plan relies on calling external Python APIs from MQL5 using `WebRequest()`. Many brokers block this functionality for security reasons. We **must** verify it works before proceeding.

## 📋 Prerequisites

- MT5 Terminal installed
- Python 3.8+ installed (for local API testing)
- Internet connection
- Admin access to configure MT5 settings

## 🚀 Quick Start (5 Steps)

### Step 1: Configure MT5 WebRequest Whitelist

1. Open MT5 Terminal
2. Go to: **Tools → Options → Expert Advisors**
3. Check the box: **"Allow WebRequest for listed URLs"**
4. Add these URLs to the whitelist (one per line):
   ```
   http://httpbin.org
   http://localhost:8000
   https://httpbin.org
   ```
5. Click **OK**
6. **Restart MT5** (important!)

### Step 2: Compile the Test EA

1. Open MetaEditor (F4 in MT5)
2. Navigate to: `Experts\Advisors\LulaMultiInstrumentEA\Tests\Test_WebRequest.mq5`
3. Click **Compile** (F7)
4. Verify **0 errors** in the log

### Step 3: Run Basic Test

1. In MT5, attach `Test_WebRequest` EA to any chart
2. Check the **Experts** tab in Terminal
3. Look for output starting with:
   ```
   ========================================
   WebRequest Functionality Test Suite
   ========================================
   ```

### Step 4: Interpret Results

**✅ SUCCESS** - You should see:
```
>>> Test: WebRequest Availability Check
✅ SUCCESS: WebRequest is working!
   HTTP Code: 200
```

**❌ FAILURE** - If you see error 4060:
```
❌ CRITICAL: WebRequest is NOT ALLOWED!
   Action Required:
   1. Open MT5: Tools → Options → Expert Advisors
   ...
```

### Step 5: Test Local API (Optional)

1. Install Python dependencies:
   ```bash
   pip install fastapi uvicorn pydantic
   ```

2. Start the test server:
   ```bash
   cd Tests
   python test_ml_api.py
   ```

3. Verify server is running:
   - Open browser: http://localhost:8000/docs
   - You should see API documentation

4. Re-run the Test_WebRequest EA
5. Check for "Local API Tests" section in logs

## 📊 Test Results Interpretation

### All Tests Pass ✅

Example output:
```
--- All Tests Completed ---

========================================
Test Suite Complete
Tests Passed: 10
Tests Failed: 0
Success Rate: 100.0%
========================================
```

**✅ Action**: Proceed to Phase 0 (ML-Lite implementation)

### WebRequest Blocked ❌

Example output:
```
❌ CRITICAL: WebRequest is NOT ALLOWED!
Tests Passed: 0
Tests Failed: 10
```

**Next steps**:
1. Double-check whitelist configuration
2. Restart MT5
3. If still blocked, contact broker support
4. Consider switching brokers or using ML-Lite only approach

### Partial Success ⚠️

Example output:
```
Tests Passed: 7
Tests Failed: 3
Success Rate: 70.0%
```

**Review which tests failed**:
- Public API fails → Network/firewall issue
- Local API fails → Python server not running (expected if you haven't started it)
- JSON tests fail → Code issue (report this)

## 🔧 Troubleshooting

### Error 4060: WebRequest Not Allowed

**Cause**: URL not whitelisted in MT5 settings

**Fix**:
1. Verify URLs are in whitelist (no typos!)
2. Make sure checkbox is enabled
3. Restart MT5 completely
4. Try again

### Error 5203: Request Timeout

**Cause**: Network issue or firewall blocking

**Fix**:
1. Check internet connection
2. Try increasing timeout (edit `InpTimeout` in EA params)
3. Check Windows Firewall settings
4. Try with VPN disabled

### Zero Response / No Output

**Cause**: EA not running or compilation error

**Fix**:
1. Check Experts tab shows "WebRequest Functionality Test Suite"
2. Verify EA is attached to chart (smiley face icon)
3. Check for compilation errors in MetaEditor
4. Enable "Allow DLL imports" and "Allow WebRequest" in EA properties

### Local API Test Fails

**Cause**: Python server not running

**Fix**:
1. Start server: `python test_ml_api.py`
2. Verify in browser: http://localhost:8000/health
3. Check firewall isn't blocking port 8000

## 📁 File Structure

```
LulaMultiInstrumentEA/
├── Core/
│   └── ML/
│       ├── C_HTTPClient.mqh       # HTTP wrapper for WebRequest
│       └── C_JSONHelper.mqh       # JSON serialization/parsing
└── Tests/
    ├── Test_WebRequest.mq5        # Comprehensive test EA
    ├── test_ml_api.py             # Python FastAPI mock server
    └── WEBREQUEST_SETUP_GUIDE.md  # This file
```

## 🎯 Success Criteria

For this phase to be **complete**, you need:

- [x] MT5 WebRequest configured and enabled
- [x] Test EA compiled without errors
- [x] Public API test (httpbin.org) returns HTTP 200
- [x] JSON creation/parsing tests pass
- [ ] Local API test passes (optional but recommended)
- [ ] No error 4060 in any test

## 🚦 Next Steps

### If Tests Pass ✅

1. Review implementation plan: `implementation_plan.md`
2. Start Phase 0: ML-Lite foundation
3. Implement `C_SignalScorer.mqh`
4. Begin data collection

### If Tests Fail ❌

1. Document which tests failed
2. Check broker WebRequest policy
3. Consider alternatives:
   - Switch to broker that allows WebRequest
   - Use C++ DLL approach (complex)
   - Stick with ML-Lite only (no external API)

## 📞 Getting Help

If you encounter issues:

1. Check the **Experts log** in MT5 Terminal
2. Note the exact error code and message
3. Review this troubleshooting guide
4. Check broker's WebRequest policy documentation

## 🔗 References

- [MQL5 WebRequest Documentation](https://www.mql5.com/en/docs/common/webrequest)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [httpbin.org Testing Service](https://httpbin.org/)

---

**Last Updated**: 2026-01-01
**Version**: 1.0
