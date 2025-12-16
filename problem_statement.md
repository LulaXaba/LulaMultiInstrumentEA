# Problem Statement: Logic Error in Adaptive MA Calculation

## 1. Critical Logic Failure in `C_TrendDetector.mqh`
The `C_TrendDetector::GetTrendDirection` method explicitly requests a calculation of only **3 bars** of history:
```cpp
// C_TrendDetector.mqh
if(!m_hFastMA.Calculate(3) || !m_hSlowMA.Calculate(3))
   return TREND_UNKNOWN;
```
This is insufficient for the Adaptive Moving Average (AMA) algorithm implemented in `C_AdaptiveMA.mqh`.

## 2. Insufficient History for `C_AdaptiveMA.mqh`
The `C_AdaptiveMA` class implements a recursive AMA calculation that requires a significant history to stabilize (seed value + recursive smoothing).
- It uses an Efficiency Ratio (ER) period (default 5).
- It iterates from `m_rates_total - (m_er_period + 2)` down to 0.
- With `bars = 3` and `m_er_period = 5`:
  - `m_rates_total` = 3
  - Start Index = `3 - (5 + 2)` = `-4`
  - The loop `for(int i = -4; i >= 0; i--)` **never executes**.
- The `m_ama_buffer` remains unpopulated (or zero-filled).
- `GetValue(1)` returns `0.0`.

## 3. Consequence
- `GetTrendDirection` receives `0.0` for both Fast and Slow MAs.
- It returns `TREND_UNKNOWN` (or `TREND_SIDEWAYS` if 0.0 == 0.0, but the logic checks `fastMA == 0.0` and returns `TREND_UNKNOWN`).
- The EA will **never generate a valid trend signal** (`TREND_UP` or `TREND_DOWN`).
- **No trades will be executed.**

## 4. Recommendation
- **Increase History**: `C_TrendDetector` must request enough bars (e.g., 200 or more) to allow the AMA to stabilize.
- **Optimize Calculation**: `C_AdaptiveMA` should ideally support incremental calculation (calculating only new bars) rather than recalculating the entire history on every tick, or at least be efficient about it.
- **Fix Call Site**: Change `Calculate(3)` to `Calculate(300)` (or a configurable `m_lookback` parameter) in `C_TrendDetector`.
