//+------------------------------------------------------------------+
//|                                        IndicatorHelpers_MQL5.mqh |
//|                   Helper functions for MQL5 indicator access     |
//+------------------------------------------------------------------+
#property copyright "LulaXaba"
#property strict

// MQL4-style constants for MQL5 compatibility
#define OP_BUY 0
#define OP_SELL 1
#define MODE_EMA 1
#define MODE_SMA 0

//+------------------------------------------------------------------+
//| Get single MA value (MQL4-like interface for MQL5)              |
//+------------------------------------------------------------------+
double GetMA(string symbol, ENUM_TIMEFRAMES tf, int period, int shift_ma, int ma_method, int applied_price, int bar_shift)
{
   int handle = iMA(symbol, tf, period, shift_ma, (ENUM_MA_METHOD)ma_method, (ENUM_APPLIED_PRICE)applied_price);
   if(handle == INVALID_HANDLE) return 0.0;
   
   double buffer[1];
   if(CopyBuffer(handle, 0, bar_shift, 1, buffer) <= 0) return 0.0;
   
   IndicatorRelease(handle);
   return buffer[0];
}

//+------------------------------------------------------------------+
//| Get single ADX value                                             |
//+------------------------------------------------------------------+
double GetADX(string symbol, ENUM_TIMEFRAMES tf, int period, int bar_shift)
{
   int handle = iADX(symbol, tf, period);
   if(handle == INVALID_HANDLE) return 0.0;
   
   double buffer[1];
   if(CopyBuffer(handle, 0, bar_shift, 1, buffer) <= 0) return 0.0; // Buffer 0 = MAIN line
   
   IndicatorRelease(handle);
   return buffer[0];
}

//+------------------------------------------------------------------+
//| Get single RSI value                                             |
//+------------------------------------------------------------------+
double GetRSI(string symbol, ENUM_TIMEFRAMES tf, int period, int applied_price, int bar_shift)
{
   int handle = iRSI(symbol, tf, period, (ENUM_APPLIED_PRICE)applied_price);
   if(handle == INVALID_HANDLE) return 50.0;
   
   double buffer[1];
   if(CopyBuffer(handle, 0, bar_shift, 1, buffer) <= 0) return 50.0;
   
   IndicatorRelease(handle);
   return buffer[0];
}

//+------------------------------------------------------------------+
//| Get MA CD value (MAIN or SIGNAL line)                           |
//+------------------------------------------------------------------+
double GetMACD(string symbol, ENUM_TIMEFRAMES tf, int fast, int slow, int signal, int applied_price, int buffer_num, int bar_shift)
{
   int handle = iMACD(symbol, tf, fast, slow, signal, (ENUM_APPLIED_PRICE)applied_price);
   if(handle == INVALID_HANDLE) return 0.0;
   
   double buffer[1];
   if(CopyBuffer(handle, buffer_num, bar_shift, 1, buffer) <= 0) return 0.0;
   
   IndicatorRelease(handle);
   return buffer[0];
}

//+------------------------------------------------------------------+
//| Get single ATR value                                             |
//+------------------------------------------------------------------+
double GetATR(string symbol, ENUM_TIMEFRAMES tf, int period, int bar_shift)
{
   int handle = iATR(symbol, tf, period);
   if(handle == INVALID_HANDLE) return 0.0;
   
   double buffer[1];
   if(CopyBuffer(handle, 0, bar_shift, 1, buffer) <= 0) return 0.0;
   
   IndicatorRelease(handle);
   return buffer[0];
}

//+------------------------------------------------------------------+
//| Get Bollinger Band value                                         |
//+------------------------------------------------------------------+
double GetBands(string symbol, ENUM_TIMEFRAMES tf, int period, int deviation, int shift_ma, int applied_price, int buffer_num, int bar_shift)
{
   int handle = iBands(symbol, tf, period, deviation, shift_ma, (ENUM_APPLIED_PRICE)applied_price);
   if(handle == INVALID_HANDLE) return 0.0;
   
   double buffer[1];
   // Buffer 0 = BASE, 1 = UPPER, 2 = LOWER
   if(CopyBuffer(handle, buffer_num, bar_shift, 1, buffer) <= 0) return 0.0;
   
   IndicatorRelease(handle);
   return buffer[0];
}
//+------------------------------------------------------------------+
