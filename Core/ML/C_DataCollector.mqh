//+------------------------------------------------------------------+
//|                                           C_DataCollector.mqh    |
//|                   LulaMultiInstrumentEA - ML Data Collection     |
//|                                   Phase 0: ML-Lite Foundation   |
//+------------------------------------------------------------------+
#property copyright "LulaXaba"
#property link      "https://github.com/LulaXaba/LulaMultiInstrumentEA"
#property version   "1.00"
#property strict

#include "IndicatorHelpers_MQL5.mqh"
#include "C_SignalScorer.mqh"

//+------------------------------------------------------------------+
//| Signal Data Structure - All data logged per signal              |
//+------------------------------------------------------------------+
struct SignalData
{
   // Identity & Metadata
   string tradeId;              // Unique identifier (timestamp-based)
   datetime timestamp;          // Signal generation time
   string symbol;               // Trading symbol
   int timeframe;              // Timeframe
   int direction;              // OP_BUY or OP_SELL
   
   // Signal Quality (from C_SignalScorer)
   double score;               // Overall quality score (0.0-1.0)
   int recommendation;         // SKIP/CONSIDER/TAKE/STRONG_TAKE
   
   // Trade Setup Proposal
   double entryPrice;          // Proposed entry price
   double stopLoss;            // Proposed stop loss
   double takeProfit;          // Proposed take profit
   double rrRatio;             // Risk:Reward ratio
   
   // Feature Arrays (30+ features)
   double trendFeatures[8];        // Trend features
   double momentumFeatures[7];     // Momentum features
   double volatilityFeatures[5];   // Volatility features
   double priceActionFeatures[5];  // Price action features
   double contextFeatures[5];      // Market context features
};

//+------------------------------------------------------------------+
//| Trade Outcome Structure - Final results                         |
//+------------------------------------------------------------------+
struct TradeOutcome
{
   string tradeId;             // Links to SignalData
   bool executed;              // Was trade actually taken?
   
   // Entry Details
   double actualEntry;         // Actual entry price
   datetime entryTime;         // Entry execution time
   
   // Trade Performance
   double mfe;                 // Max Favorable Excursion (pips)
   double mae;                 // Max Adverse Excursion (pips)
   
   // Exit Details
   double exitPrice;           // Final exit price
   datetime exitTime;          // Exit time
   double profitPips;          // Final P/L in pips
   double profitCurrency;      // Final P/L in account currency
   
   // Classification
   string outcome;             // "WIN", "LOSS", "BREAKEVEN"
   string exitReason;          // "TP", "SL", "MANUAL", "TIMEOUT"
};

//+------------------------------------------------------------------+
//| C_DataCollector - ML Data Collection Engine                      |
//+------------------------------------------------------------------+
class C_DataCollector
{
private:
   // File Management
   int m_fileHandle;
   string m_dataPath;
   string m_currentFilePath;
   datetime m_lastFlush;
   int m_maxFileSizeMB;
   int m_flushIntervalMinutes;
   
   // Active Trades Tracking (for MFE/MAE)
   string m_activeTradeIds[];
   double m_maxFavorable[];
   double m_maxAdverse[];
   
   // CSV Management Methods
   bool OpenOrCreateFile();
   bool WriteHeader();
   string GenerateFilePath(datetime time);
   bool RotateFileIfNeeded();
   void FlushToDisk();
   void CloseFile();
   
   // Feature Extraction Methods
   void ExtractTrendFeatures(string symbol, ENUM_TIMEFRAMES tf, double &features[]);
   void ExtractMomentumFeatures(string symbol, ENUM_TIMEFRAMES tf, double &features[]);
   void ExtractVolatilityFeatures(string symbol, ENUM_TIMEFRAMES tf, double &features[]);
   void ExtractPriceActionFeatures(string symbol, ENUM_TIMEFRAMES tf, double &features[]);
   void ExtractContextFeatures(string symbol, ENUM_TIMEFRAMES tf, double &features[]);
   
   // Helper Methods
   string GenerateTradeId();
   string DoubleArrayToCSV(double &arr[], int size);
   int GetSessionType();
   double CalculateSlope(string symbol, ENUM_TIMEFRAMES tf, int period, int ma_method, int lookback);
   
public:
   // Constructor/Destructor
   C_DataCollector();
   ~C_DataCollector();
   
   // Initialization
   bool Initialize(string dataPath = "ML_Data", 
                   int maxFileSizeMB = 50,
                   int flushIntervalMinutes = 60);
   
   void Shutdown();
   
   // Main Logging Methods
   string LogSignal(SignalScore &signalScore, 
                    string symbol, 
                    ENUM_TIMEFRAMES timeframe,
                    int direction,
                    double entryPrice,
                    double stopLoss,
                    double takeProfit);
   
   bool LogOutcome(string tradeId, TradeOutcome &outcome);
   
   // Trade Tracking
   void UpdateMFE_MAE(string tradeId, double currentPrice, int direction);
   void PeriodicFlush();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
C_DataCollector::C_DataCollector()
{
   m_fileHandle = INVALID_HANDLE;
   m_dataPath = "ML_Data";
   m_currentFilePath = "";
   m_lastFlush = TimeCurrent();
   m_maxFileSizeMB = 50;
   m_flushIntervalMinutes = 60;
   
   ArrayResize(m_activeTradeIds, 0);
   ArrayResize(m_maxFavorable, 0);
   ArrayResize(m_maxAdverse, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
C_DataCollector::~C_DataCollector()
{
   Shutdown();
}

//+------------------------------------------------------------------+
//| Initialize data collector                                        |
//+------------------------------------------------------------------+
bool C_DataCollector::Initialize(string dataPath, int maxFileSizeMB, int flushIntervalMinutes)
{
   m_dataPath = dataPath;
   m_maxFileSizeMB = maxFileSizeMB;
   m_flushIntervalMinutes = flushIntervalMinutes;
   
   Print("Initializing C_DataCollector...");
   Print("   Data Path: ", m_dataPath);
   Print("   Max File Size: ", m_maxFileSizeMB, " MB");
   Print("   Flush Interval: ", m_flushIntervalMinutes, " minutes");
   
   // Create data directory if it doesn't exist
   // Note: Directory will be created in MQL5/Files/
   if(!FolderCreate(m_dataPath, 0))
   {
      int error = GetLastError();
      // Error 5006 means folder already exists, which is fine
      if(error != 5006 && error != 0)
      {
         Print("Warning: Could not create directory (error ", error, ")");
      }
   }
   else
   {
      Print("Created directory: MQL5/Files/", m_dataPath);
   }
   
   // Open or create CSV file
   if(!OpenOrCreateFile())
   {
      Print("ERROR: Failed to open/create data file");
      return false;
   }
   
   Print("✅ C_DataCollector initialized successfully");
   return true;
}

//+------------------------------------------------------------------+
//| Shutdown and cleanup                                             |
//+------------------------------------------------------------------+
void C_DataCollector::Shutdown()
{
   if(m_fileHandle != INVALID_HANDLE)
   {
      Print("Shutting down C_DataCollector, flushing data...");
      FlushToDisk();
      CloseFile();
      Print("✅ C_DataCollector shutdown complete");
   }
}

//+------------------------------------------------------------------+
//| Open or create CSV file for current month                        |
//+------------------------------------------------------------------+
bool C_DataCollector::OpenOrCreateFile()
{
   // Generate file path for current month
   m_currentFilePath = GenerateFilePath(TimeCurrent());
   
   Print("Attempting to open file: ", m_currentFilePath);
   Print("Full path will be: MQL5/Files/", m_currentFilePath);
   
   // Check if file exists by trying to open it for reading
   bool fileExists = false;
   int testHandle = FileOpen(m_currentFilePath, FILE_READ|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_ANSI);
   if(testHandle != INVALID_HANDLE)
   {
      fileExists = true;
      FileClose(testHandle);
      Print("File exists, will append to it");
   }
   else
   {
      Print("File does not exist, will create new file");
   }
   
   // Open file with shared access (allow other EAs to read/write)
   int flags = FILE_WRITE|FILE_READ|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_ANSI;
   m_fileHandle = FileOpen(m_currentFilePath, flags);
   
   if(m_fileHandle == INVALID_HANDLE)
   {
      int error = GetLastError();
      Print("ERROR: Failed to open file: ", m_currentFilePath);
      Print("   Error code: ", error);
      Print("   Full path should be: MQL5/Files/", m_currentFilePath);
      
      // Try alternative: create with FILE_WRITE only first
      if(!fileExists)
      {
         Print("Attempting alternative: FILE_WRITE only...");
         m_fileHandle = FileOpen(m_currentFilePath, FILE_WRITE|FILE_ANSI);
         if(m_fileHandle != INVALID_HANDLE)
         {
            Print("Success with FILE_WRITE only");
         }
         else
         {
            Print("Alternative also failed, error: ", GetLastError());
            return false;
         }
      }
      else
      {
         return false;
      }
   }
   
   // If new file, write header
   if(!fileExists)
   {
      if(!WriteHeader())
      {
         Print("ERROR: Failed to write CSV header");
         CloseFile();
         return false;
      }
      Print("Created new data file with header: ", m_currentFilePath);
   }
   else
   {
      // Move to end of file for appending
      FileSeek(m_fileHandle, 0, SEEK_END);
      Print("Opened existing data file for appending: ", m_currentFilePath);
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Write CSV header with all column names                           |
//+------------------------------------------------------------------+
bool C_DataCollector::WriteHeader()
{
   if(m_fileHandle == INVALID_HANDLE) return false;
   
   string header = "";
   
   // Metadata columns
   header += "TradeID,Timestamp,Symbol,Timeframe,Direction,";
   header += "Score,Recommendation,";
   header += "EntryPrice,StopLoss,TakeProfit,RRRatio,";
   
   // Trend features (8)
   header += "ADX_14,ADX_20,ATR_Norm,MA20_Slope,MA50_Slope,MA200_Slope,TrendDuration,HTF_Aligned,";
   
   // Momentum features (7)
   header += "RSI_14,MACD_Main,MACD_Signal,Stoch_K,Stoch_D,ROC,Williams_R,";
   
   // Volatility features (5)
   header += "ATR_14,HistVol_20,BB_Width,BB_Position,TR_Ratio,";
   
   // Price action features (5)
   header += "Dist_HH50,Dist_LL50,BodyRatio,ConsecBars,PriceMA_Dist,";
   
   // Context features (5)
   header += "Session,Spread,Hour,DayOfWeek,VolRegime,";
   
   // Outcome columns
   header += "Executed,ActualEntry,EntryTime,MFE,MAE,";
   header += "ExitPrice,ExitTime,ProfitPips,ProfitCurrency,Outcome,ExitReason";
   
   FileWrite(m_fileHandle, header);
   
   return true;
}

//+------------------------------------------------------------------+
//| Generate file path for given month                               |
//+------------------------------------------------------------------+
string C_DataCollector::GenerateFilePath(datetime time)
{
   MqlDateTime dt;
   TimeToStruct(time, dt);
   
   string filename = StringFormat("signals_%04d-%02d.csv", dt.year, dt.mon);
   return m_dataPath + "/" + filename;
}

//+------------------------------------------------------------------+
//| Generate unique trade ID                                         |
//+------------------------------------------------------------------+
string C_DataCollector::GenerateTradeId()
{
   // Format: YYYYMMDD_HHMMSS_MILLISECONDS
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   
   int millis = GetTickCount() % 1000;
   
   return StringFormat("%04d%02d%02d_%02d%02d%02d_%03d",
                       dt.year, dt.mon, dt.day,
                       dt.hour, dt.min, dt.sec,
                       millis);
}

//+------------------------------------------------------------------+
//| Close current file                                               |
//+------------------------------------------------------------------+
void C_DataCollector::CloseFile()
{
   if(m_fileHandle != INVALID_HANDLE)
   {
      FileClose(m_fileHandle);
      m_fileHandle = INVALID_HANDLE;
   }
}

//+------------------------------------------------------------------+
//| Flush data to disk                                               |
//+------------------------------------------------------------------+
void C_DataCollector::FlushToDisk()
{
   if(m_fileHandle != INVALID_HANDLE)
   {
      FileFlush(m_fileHandle);
      m_lastFlush = TimeCurrent();
   }
}

//+------------------------------------------------------------------+
//| Check if periodic flush is needed                                |
//+------------------------------------------------------------------+
void C_DataCollector::PeriodicFlush()
{
   if(TimeCurrent() - m_lastFlush >= m_flushIntervalMinutes * 60)
   {
      FlushToDisk();
   }
}

//+------------------------------------------------------------------+
//| Convert double array to CSV string                               |
//+------------------------------------------------------------------+
string C_DataCollector::DoubleArrayToCSV(double &arr[], int size)
{
   string result = "";
   for(int i = 0; i < size; i++)
   {
      result += DoubleToString(arr[i], 6);
      if(i < size - 1) result += ",";
   }
   return result;
}

//+------------------------------------------------------------------+
//| Get current session type (0=Asian, 1=London, 2=NY, 3=Overlap)   |
//+------------------------------------------------------------------+
int C_DataCollector::GetSessionType()
{
   datetime now = TimeGMT();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   int hour = dt.hour;
   
   // Session times in GMT
   bool london = (hour >= 8 && hour < 17);
   bool ny = (hour >= 13 && hour < 22);
   bool asian = (hour >= 0 && hour < 9);
   
   if(london && ny) return 3;  // Overlap
   if(ny) return 2;            // NY
   if(london) return 1;        // London
   if(asian) return 0;         // Asian
   
   return 0; // Default to Asian for off-hours
}

//+------------------------------------------------------------------+
//| Calculate MA slope over lookback period                          |
//+------------------------------------------------------------------+
double C_DataCollector::CalculateSlope(string symbol, ENUM_TIMEFRAMES tf, 
                                       int period, int ma_method, int lookback)
{
   double ma_current = GetMA(symbol, tf, period, 0, ma_method, 1, 1);
   double ma_past = GetMA(symbol, tf, period, 0, ma_method, 1, lookback + 1);
   
   if(ma_past == 0) return 0.0;
   
   // Return slope as percentage change
   return ((ma_current - ma_past) / ma_past) * 100.0;
}

//+------------------------------------------------------------------+
//| Extract Trend Features (8 features)                              |
//+------------------------------------------------------------------+
void C_DataCollector::ExtractTrendFeatures(string symbol, ENUM_TIMEFRAMES tf, double &features[])
{
   ArrayResize(features, 8);
   
   // Feature 0: ADX(14)
   features[0] = GetADX(symbol, tf, 14, 1);
   
   // Feature 1: ADX(20)
   features[1] = GetADX(symbol, tf, 20, 1);
   
   // Feature 2: ATR normalized by price
   double atr = GetATR(symbol, tf, 14, 1);
   double price = SymbolInfoDouble(symbol, SYMBOL_BID);
   features[2] = (price > 0) ? atr / price : 0.0;
   
   // Feature 3: MA20 slope (5 bars)
   features[3] = CalculateSlope(symbol, tf, 20, MODE_EMA, 5);
   
   // Feature 4: MA50 slope (5 bars)
   features[4] = CalculateSlope(symbol, tf, 50, MODE_EMA, 5);
   
   // Feature 5: MA200 slope (10 bars)
   features[5] = CalculateSlope(symbol, tf, 200, MODE_SMA, 10);
   
   // Feature 6: Trend duration (count bars in same direction)
   double ma_fast = GetMA(symbol, tf, 20, 0, MODE_EMA, 1, 1);
   double ma_slow = GetMA(symbol, tf, 50, 0, MODE_EMA, 1, 1);
   bool current_trend_up = ma_fast > ma_slow;
   
   int duration = 0;
   for(int i = 1; i < 100; i++)
   {
      double ma_f = GetMA(symbol, tf, 20, 0, MODE_EMA, 1, i);
      double ma_s = GetMA(symbol, tf, 50, 0, MODE_EMA, 1, i);
      bool trend_up = ma_f > ma_s;
      
      if(trend_up == current_trend_up)
         duration++;
      else
         break;
   }
   features[6] = (double)duration;
   
   // Feature 7: HTF alignment (1 if HTF trend agrees, 0 otherwise)
   ENUM_TIMEFRAMES htf = PERIOD_CURRENT;
   switch(tf)
   {
      case PERIOD_M1:  htf = PERIOD_M5; break;
      case PERIOD_M5:  htf = PERIOD_M15; break;
      case PERIOD_M15: htf = PERIOD_H1; break;
      case PERIOD_H1:  htf = PERIOD_H4; break;
      case PERIOD_H4:  htf = PERIOD_D1; break;
      default: htf = tf; break;
   }
   
   double htf_ma_fast = GetMA(symbol, htf, 20, 0, MODE_EMA, 1, 1);
   double htf_ma_slow = GetMA(symbol, htf, 50, 0, MODE_EMA, 1, 1);
   bool htf_trend_up = htf_ma_fast > htf_ma_slow;
   
   features[7] = (htf_trend_up == current_trend_up) ? 1.0 : 0.0;
}

//+------------------------------------------------------------------+
//| Extract Momentum Features (7 features)                           |
//+------------------------------------------------------------------+
void C_DataCollector::ExtractMomentumFeatures(string symbol, ENUM_TIMEFRAMES tf, double &features[])
{
   ArrayResize(features, 7);
   
   // Feature 0: RSI(14)
   features[0] = GetRSI(symbol, tf, 14, 1, 1);
   
   // Feature 1: MACD main line
   features[1] = GetMACD(symbol, tf, 12, 26, 9, 1, 0, 1);
   
   // Feature 2: MACD signal line
   features[2] = GetMACD(symbol, tf, 12, 26, 9, 1, 1, 1);
   
   // Feature 3: Stochastic %K
   int stoch_handle = iStochastic(symbol, tf, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
   double stoch_k[1];
   if(stoch_handle != INVALID_HANDLE && CopyBuffer(stoch_handle, 0, 1, 1, stoch_k) > 0)
      features[3] = stoch_k[0];
   else
      features[3] = 50.0;
   IndicatorRelease(stoch_handle);
   
   // Feature 4: Stochastic %D
   int stoch_handle2 = iStochastic(symbol, tf, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
   double stoch_d[1];
   if(stoch_handle2 != INVALID_HANDLE && CopyBuffer(stoch_handle2, 1, 1, 1, stoch_d) > 0)
      features[4] = stoch_d[0];
   else
      features[4] = 50.0;
   IndicatorRelease(stoch_handle2);
   
   // Feature 5: ROC (Rate of Change, 10 period)
   double close_current = iClose(symbol, tf, 1);
   double close_past = iClose(symbol, tf, 11);
   features[5] = (close_past > 0) ? ((close_current - close_past) / close_past) * 100.0 : 0.0;
   
   // Feature 6: Williams %R (14 period)
   double highest = iHigh(symbol, tf, 1);
   double lowest = iLow(symbol, tf, 1);
   for(int i = 2; i <= 14; i++)
   {
      double high = iHigh(symbol, tf, i);
      double low = iLow(symbol, tf, i);
      if(high > highest) highest = high;
      if(low < lowest) lowest = low;
   }
   double range = highest - lowest;
   features[6] = (range > 0) ? ((highest - close_current) / range) * -100.0 : 0.0;
}

//+------------------------------------------------------------------+
//| Extract Volatility Features (5 features)                         |
//+------------------------------------------------------------------+
void C_DataCollector::ExtractVolatilityFeatures(string symbol, ENUM_TIMEFRAMES tf, double &features[])
{
   ArrayResize(features, 5);
   
   // Feature 0: ATR(14)
   features[0] = GetATR(symbol, tf, 14, 1);
   
   // Feature 1: Historical volatility (20 bars standard deviation of returns)
   double returns[20];
   for(int i = 0; i < 20; i++)
   {
      double close_current = iClose(symbol, tf, i + 1);
      double close_prev = iClose(symbol, tf, i + 2);
      returns[i] = (close_prev > 0) ? (close_current - close_prev) / close_prev : 0.0;
   }
   
   double mean = 0.0;
   for(int i = 0; i < 20; i++)
      mean += returns[i];
   mean /= 20.0;
   
   double variance = 0.0;
   for(int i = 0; i < 20; i++)
      variance += MathPow(returns[i] - mean, 2);
   variance /= 20.0;
   
   features[1] = MathSqrt(variance) * 100.0; // Convert to percentage
   
   // Feature 2: Bollinger Band width
   double bb_upper = GetBands(symbol, tf, 20, 2, 0, 1, 1, 1);
   double bb_lower = GetBands(symbol, tf, 20, 2, 0, 1, 2, 1);
   double bb_middle = GetBands(symbol, tf, 20, 2, 0, 1, 0, 1);
   features[2] = (bb_middle > 0) ? (bb_upper - bb_lower) / bb_middle : 0.0;
   
   // Feature 3: BB position (where price is within bands)
   double price = iClose(symbol, tf, 1);
   double bb_range = bb_upper - bb_lower;
   features[3] = (bb_range > 0) ? (price - bb_lower) / bb_range : 0.5;
   
   // Feature 4: True Range ratio (current TR / ATR)
   double high = iHigh(symbol, tf, 1);
   double low = iLow(symbol, tf, 1);
   double prev_close = iClose(symbol, tf, 2);
   double tr = MathMax(high - low, MathMax(MathAbs(high - prev_close), MathAbs(low - prev_close)));
   features[4] = (features[0] > 0) ? tr / features[0] : 1.0;
}

//+------------------------------------------------------------------+
//| Extract Price Action Features (5 features)                       |
//+------------------------------------------------------------------+
void C_DataCollector::ExtractPriceActionFeatures(string symbol, ENUM_TIMEFRAMES tf, double &features[])
{
   ArrayResize(features, 5);
   
   double current_price = iClose(symbol, tf, 1);
   
   // Feature 0: Distance from 50-bar high (%)
   double high_50 = iHigh(symbol, tf, 1);
   for(int i = 2; i <= 50; i++)
   {
      double h = iHigh(symbol, tf, i);
      if(h > high_50) high_50 = h;
   }
   features[0] = (high_50 > 0) ? ((current_price - high_50) / high_50) * 100.0 : 0.0;
   
   // Feature 1: Distance from 50-bar low (%)
   double low_50 = iLow(symbol, tf, 1);
   for(int i = 2; i <= 50; i++)
   {
      double l = iLow(symbol, tf, i);
      if(l < low_50) low_50 = l;
   }
   features[1] = (low_50 > 0) ? ((current_price - low_50) / low_50) * 100.0 : 0.0;
   
   // Feature 2: Candle body/range ratio
   double open = iOpen(symbol, tf, 1);
   double close = iClose(symbol, tf, 1);
   double high = iHigh(symbol, tf, 1);
   double low = iLow(symbol, tf, 1);
   double body = MathAbs(close - open);
   double range = high - low;
   features[2] = (range > 0) ? body / range : 0.0;
   
   // Feature 3: Consecutive up/down bars
   bool is_up = close > open;
   int consec = 1;
   for(int i = 2; i <= 10; i++)
   {
      double bar_open = iOpen(symbol, tf, i);
      double bar_close = iClose(symbol, tf, i);
      bool bar_up = bar_close > bar_open;
      
      if(bar_up == is_up)
         consec++;
      else
         break;
   }
   features[3] = (double)consec * (is_up ? 1.0 : -1.0);
   
   // Feature 4: Price vs MA50 distance (%)
   double ma50 = GetMA(symbol, tf, 50, 0, MODE_EMA, 1, 1);
   features[4] = (ma50 > 0) ? ((current_price - ma50) / ma50) * 100.0 : 0.0;
}

//+------------------------------------------------------------------+
//| Extract Market Context Features (5 features)                     |
//+------------------------------------------------------------------+
void C_DataCollector::ExtractContextFeatures(string symbol, ENUM_TIMEFRAMES tf, double &features[])
{
   ArrayResize(features, 5);
   
   // Feature 0: Session (0=Asian, 1=London, 2=NY, 3=Overlap)
   features[0] = (double)GetSessionType();
   
   // Feature 1: Spread in pips
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double spread_pips = (point > 0) ? (ask - bid) / point / 10.0 : 0.0;
   features[1] = spread_pips;
   
   // Feature 2: Hour (GMT)
   datetime now = TimeGMT();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   features[2] = (double)dt.hour;
   
   // Feature 3: Day of week (0=Sunday, 6=Saturday)
   features[3] = (double)dt.day_of_week;
   
   // Feature 4: Volatility regime (0=Low, 1=Med, 2=High)
   double atr = GetATR(symbol, tf, 14, 1);
   double atr_avg = 0.0;
   for(int i = 1; i <= 50; i++)
      atr_avg += GetATR(symbol, tf, 14, i);
   atr_avg /= 50.0;
   
   if(atr_avg > 0)
   {
      double atr_ratio = atr / atr_avg;
      if(atr_ratio < 0.8)
         features[4] = 0.0; // Low volatility
      else if(atr_ratio < 1.2)
         features[4] = 1.0; // Medium volatility
      else
         features[4] = 2.0; // High volatility
   }
   else
      features[4] = 1.0;
}

//+------------------------------------------------------------------+
//| Log Signal - Main logging method                                 |
//+------------------------------------------------------------------+
string C_DataCollector::LogSignal(SignalScore &signalScore, string symbol, 
                                   ENUM_TIMEFRAMES timeframe, int direction,
                                   double entryPrice, double stopLoss, double takeProfit)
{
   if(m_fileHandle == INVALID_HANDLE)
   {
      Print("ERROR: Cannot log signal, file not open");
      return "";
   }
   
   // Generate unique trade ID
   string tradeId = GenerateTradeId();
   
   // Extract all features
   double trendFeatures[8], momentumFeatures[7], volatilityFeatures[5];
   double priceActionFeatures[5], contextFeatures[5];
   
   ExtractTrendFeatures(symbol, timeframe, trendFeatures);
   ExtractMomentumFeatures(symbol, timeframe, momentumFeatures);
   ExtractVolatilityFeatures(symbol, timeframe, volatilityFeatures);
   ExtractPriceActionFeatures(symbol, timeframe, priceActionFeatures);
   ExtractContextFeatures(symbol, timeframe, contextFeatures);
   
   // Calculate R:R ratio
   double rrRatio = 0.0;
   if(stopLoss > 0 && takeProfit > 0)
   {
      double risk = MathAbs(entryPrice - stopLoss);
      double reward = MathAbs(takeProfit - entryPrice);
      rrRatio = (risk > 0) ? reward / risk : 0.0;
   }
   
   // Build CSV row
   string row = "";
   
   // Metadata
   row += tradeId + ",";
   row += TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + ",";
   row += symbol + ",";
   row += IntegerToString(timeframe) + ",";
   row += IntegerToString(direction) + ",";
   
   // Signal quality
   row += DoubleToString(signalScore.score, 6) + ",";
   row += IntegerToString((int)signalScore.recommendation) + ",";
   
   // Trade setup
   row += DoubleToString(entryPrice, 6) + ",";
   row += DoubleToString(stopLoss, 6) + ",";
   row += DoubleToString(takeProfit, 6) + ",";
   row += DoubleToString(rrRatio, 3) + ",";
   
   // Features (30 total)
   row += DoubleArrayToCSV(trendFeatures, 8) + ",";
   row += DoubleArrayToCSV(momentumFeatures, 7) + ",";
   row += DoubleArrayToCSV(volatilityFeatures, 5) + ",";
   row += DoubleArrayToCSV(priceActionFeatures, 5) + ",";
   row += DoubleArrayToCSV(contextFeatures, 5) + ",";
   
   // Outcome columns (empty for now, filled when trade closes)
   row += ",,,,,,,,,,"; // 11 empty outcome fields
   
   // Write to file
   FileWrite(m_fileHandle, row);
   
   // Periodic flush
   PeriodicFlush();
   
   return tradeId;
}

//+------------------------------------------------------------------+
//| Log Outcome - Update with trade results                          |
//+------------------------------------------------------------------+
bool C_DataCollector::LogOutcome(string tradeId, TradeOutcome &outcome)
{
   // TODO: In production, this would:
   // 1. Find the row with matching tradeId in CSV
   // 2. Update the outcome columns
   // 3. Rewrite the row
   //
   // For Phase 0, we'll use a simpler approach:
   // Log outcome to a separate file or append a new row with outcome data
   
   Print("Outcome logged for trade: ", tradeId);
   Print("   Executed: ", outcome.executed);
   if(outcome.executed)
   {
      Print("   Entry: ", outcome.actualEntry);
      Print("   Exit: ", outcome.exitPrice);
      Print("   MFE: ", outcome.mfe, " pips");
      Print("   MAE: ", outcome.mae, " pips");
      Print("   P/L: ", outcome.profitPips, " pips (", outcome.profitCurrency, " ", AccountInfoString(ACCOUNT_CURRENCY), ")");
      Print("   Outcome: ", outcome.outcome);
      Print("   Exit Reason: ", outcome.exitReason);
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Update MFE/MAE for active trade                                  |
//+------------------------------------------------------------------+
void C_DataCollector::UpdateMFE_MAE(string tradeId, double currentPrice, int direction)
{
   // Find trade in active trades array
   int index = -1;
   for(int i = 0; i < ArraySize(m_activeTradeIds); i++)
   {
      if(m_activeTradeIds[i] == tradeId)
      {
         index = i;
         break;
      }
   }
   
   // If not found, add it
   if(index < 0)
   {
      index = ArraySize(m_activeTradeIds);
      ArrayResize(m_activeTradeIds, index + 1);
      ArrayResize(m_maxFavorable, index + 1);
      ArrayResize(m_maxAdverse, index + 1);
      
      m_activeTradeIds[index] = tradeId;
      m_maxFavorable[index] = 0.0;
      m_maxAdverse[index] = 0.0;
   }
   
   // Update MFE/MAE
   // Note: This is simplified - in production would track entry price and calculate properly
   // For now, just track the values (caller should calculate pips)
   if(currentPrice > m_maxFavorable[index])
      m_maxFavorable[index] = currentPrice;
   
   if(currentPrice < m_maxAdverse[index] || m_maxAdverse[index] == 0.0)
      m_maxAdverse[index] = currentPrice;
}
//+------------------------------------------------------------------+

