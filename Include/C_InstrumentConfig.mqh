//+------------------------------------------------------------------+
//|                                           C_InstrumentConfig.mqh |
//|        Abstract Base Class for all instrument configurations.    |
//|    This class defines the "contract" for instrument-specific     |
//|      parameters and calculations (e.g., pip value, risk).        |
//+------------------------------------------------------------------+
#property strict

// Include the new enum from the Core folder
#include "../Core/Lula_CoreEnums.mqh"

class C_InstrumentConfig
  {
protected:
   //--- Core properties
   string               m_symbol;
   ENUM_INSTRUMENT_TYPE m_type;
   int                  m_digits;           // Instrument's digits
   double               m_point;            // Instrument's point size

   //--- Blueprint-defined parameters
   double               m_atrMultiplier;      // For SL placement
   int                  m_atrPeriod;          // For ATR calculation
   double               m_maxRiskPercent;     // Max risk % (from V3 spec)
   double               m_minVolatilityPercent; // Min normalized ATR% to trade
   double               m_maxVolatilityPercent; // Max normalized ATR% to trade
   double               m_maxSpreadPips;      // Max allowed spread in pips

public:
   //--- Constructor: Set universal defaults
   C_InstrumentConfig(void)
     {
      m_symbol = "";
      m_type = TYPE_UNKNOWN;
      m_digits = 5;
      m_point = 0.00001;

      //--- Set SANE DEFAULTS (will be overridden by derived classes)
      m_atrMultiplier = 1.5;
      m_atrPeriod = 14;
      m_maxRiskPercent = 2.0;       // V3 default
      m_minVolatilityPercent = 0.05;  // 0.05%
      m_maxVolatilityPercent = 5.0;   // 5.0%
      m_maxSpreadPips = 5.0;      // 5 pips
     }

   //--- Virtual destructor is CRITICAL for proper memory management
   virtual ~C_InstrumentConfig(void) {}

   //--- Initialization (to be overridden)
   //--- This is where derived classes will set their specific values
   virtual bool      Initialize(string symbol)
     {
      m_symbol = symbol;
      
      // Load universal properties
      long digits = SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
      if(digits > 0)
         m_digits = (int)digits;
         
      m_point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      
      PrintFormat("Base C_InstrumentConfig Initialized for %s. " + 
                  "WARNING: Must be overridden by derived class.", m_symbol);
                  
      // Base class is not a valid config
      return false; 
     }

   //--- ========================================================== ---
   //--- PUBLIC GETTERS (Interface)
   //--- The main EA will call these to get configuration values
   //--- ========================================================== ---

   string            GetSymbol(void) const { return m_symbol; }
   ENUM_INSTRUMENT_TYPE GetType(void) const { return m_type; }
   double            GetAtrMultiplier(void) const { return m_atrMultiplier; }
   int               GetAtrPeriod(void) const { return m_atrPeriod; }
   double            GetMaxRiskPercent(void) const { return m_maxRiskPercent; }
   double            GetMinVolatilityPercent(void) const { return m_minVolatilityPercent; }
   double            GetMaxVolatilityPercent(void) const { return m_maxVolatilityPercent; }
   double            GetMaxSpreadPips(void) const { return m_maxSpreadPips; }

   //--- ========================================================== ---
   //--- VIRTUAL CALCULATION METHODS (The "Contract")
   //--- These MUST be implemented by each derived class
   //--- ========================================================== ---

   //--- Calculates the value of 1.0 lot * 1 pip move in ACCOUNT CURRENCY
   //--- This is the MOST IMPORTANT function for risk management.
   virtual double    GetPipValuePerLot(void)
     {
      PrintFormat("ERROR: Base GetPipValuePerLot() called for %s! " +
                  "This method must be overridden.", m_symbol);
      return 0.0;
     }

   //--- Converts a pip value (e.g., 10.0 pips) into a price distance (e.g., 0.00100)
   virtual double    PipsToPricePoints(double pips)
     {
      PrintFormat("ERROR: Base PipsToPricePoints() called for %s! " +
                  "This method must be overridden.", m_symbol);
      // Default guess (works for 5-digit forex, fails for others)
      return pips * m_point * 10.0;
     }
     
   //--- Converts a price distance (e.g. 0.00100) into pips (e.g. 10.0)
   virtual double    PricePointsToPips(double priceDistance)
     {
      PrintFormat("ERROR: Base PricePointsToPips() called for %s! " +
                  "This method must be overridden.", m_symbol);
      // Default guess
      double pip_size = m_point * 10.0;
      if(pip_size == 0) return 0;
      return priceDistance / pip_size;
     }

   //--- Checks if the current spread is acceptable
   virtual bool      IsSpreadAcceptable(void)
     {
      double spread_points = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
      double spread_pips = PricePointsToPips(spread_points * m_point);

      if(spread_pips > m_maxSpreadPips)
         return false;
         
      return true;
     }
  };
//+------------------------------------------------------------------+