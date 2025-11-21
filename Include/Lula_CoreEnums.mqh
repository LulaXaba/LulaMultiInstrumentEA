//+------------------------------------------------------------------+
//|                                              Lula_CoreEnums.mqh  |
//|               Global Enumerations for the Lula Framework         |
//|------------------------------------------------------------------+
#property strict

//--- Defines the known categories of instruments
//--- This is used by the Instrument Factory to load the correct settings
enum ENUM_INSTRUMENT_TYPE
  {
   TYPE_UNKNOWN,
   TYPE_VOLATILITY,   // e.g., VIX75, VIX75 Mini
   TYPE_FOREX,        // e.g., EURUSD, GBPUSD, USDJPY
   TYPE_INDEX_MINI    // e.g., NAS100 Mini, GER30 Mini
  };
//+------------------------------------------------------------------+