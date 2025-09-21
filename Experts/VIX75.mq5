//+------------------------------------------------------------------+
//|                                                        VIX75.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| VIX75_MA_ATR_EA.mq5                                              |
//| Multi-timeframe MA20/50 + ATR strategy                           |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

input int MA_Fast = 20;
input int MA_Slow = 50;
input int ATR_Period = 14;
input double ATR30M_MinPct = 0.008; // 0.8%
input double RiskPercent = 1.0;     // percent
input double SL_ATR_Mult = 1.0;
input double TP1_ATR_Mult = 1.5;
input double TP2_ATR_Mult = 2.5;    // uses 30M ATR
input bool UseConservativeMode = true;
input ENUM_TIMEFRAMES HTF1 = PERIOD_H1;
input ENUM_TIMEFRAMES HTF2 = PERIOD_M30;
input ENUM_TIMEFRAMES LTF = PERIOD_M15;
input double MaxRiskPercent = 2.0;
input double ToleranceBufferPct = 0.002; // 0.2%

// helper prototypes
double MA(string symbol,ENUM_TIMEFRAMES tf,int period,int shift);
double ATR_VAL(string symbol,ENUM_TIMEFRAMES tf,int period,int shift);
bool HTFTrend(int sign);
int OnInit(){
   Print("VIX75_MA_ATR_EA initialized");
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){ }

void OnTick(){
   static datetime lastTime=0;
   // operate on new LTF completed bar
   datetime t = iTime(_Symbol,LTF,0);
   if(t==lastTime) return; // wait next bar
   lastTime = t;

   double price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   // HTF trends
   double h1_fast = MA(_Symbol,HTF1,MA_Fast,1);
   double h1_slow = MA(_Symbol,HTF1,MA_Slow,1);
   double h2_fast = MA(_Symbol,HTF2,MA_Fast,1);
   double h2_slow = MA(_Symbol,HTF2,MA_Slow,1);
   int h1_trend = (h1_fast>h1_slow)?1:-1;
   int h2_trend = (h2_fast>h2_slow)?1:-1;

   if(h1_trend!=h2_trend) {
      // HTFs disagree -> no trade
      return;
   }

   // ATR checks
   double atr_h2 = ATR_VAL(_Symbol,HTF2,ATR_Period,1);
   double atr_h2_pct = atr_h2 / price;
   if(atr_h2_pct < ATR30M_MinPct) {
      // too quiet
      return;
   }

   // LTF signals
   double ltf_fast = MA(_Symbol,LTF,MA_Fast,1);
   double ltf_slow = MA(_Symbol,LTF,MA_Slow,1);
   int ltf_trend = (ltf_fast>ltf_slow)?1:-1;

   bool allowedEntry=false;
   if(UseConservativeMode){
      if(ltf_trend==h1_trend) allowedEntry=true;
   } else {
      // Aggressive: allow entry if HTF aligned and LTF either aligned or in pullback near MA area
      if(ltf_trend==h1_trend) allowedEntry=true;
      else {
         // check if LTF price near LTF MA zone and ATR( LTF ) low (weak pullback)
         double ltf_atr = ATR_VAL(_Symbol,LTF,ATR_Period,1);
         double px = SymbolInfoDouble(_Symbol,SYMBOL_BID);
         double ma20 = MA(_Symbol,LTF,MA_Fast,0);
         if(fabs(px-ma20) <= ltf_atr*0.6) allowedEntry=true; // near MA zone
      }
   }
   if(!allowedEntry) return;

   // Calculate SL and TP using ATR
   double atr_ltf = ATR_VAL(_Symbol,LTF,ATR_Period,1);
   double sl_dist = SL_ATR_Mult * atr_ltf;
   double tp1 = TP1_ATR_Mult * atr_ltf;
   double atr_h1 = ATR_VAL(_Symbol,HTF1,ATR_Period,1);
   double tp2 = TP2_ATR_Mult * atr_h2; // larger target using 30M ATR

   // Position sizing (volume)
   double risk_percent = MathMin(RiskPercent,MaxRiskPercent)/100.0;
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk_amount = balance * risk_percent;

   // convert price distance to lots: use tick value and point
   double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   double tick_value = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);

   // approximate value per point per lot (may vary by broker). Use trade calc:
   double contract_size = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_CONTRACT_SIZE);
   if(contract_size==0) contract_size=1.0;

   // risk per lot = sl_dist/point * tick_value * (tick_size/point) ... simplified approximation
   // Safer: compute required volume so that risk_amount >= sl_pips * value_per_lot
   double price_per_point = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE) / SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(price_per_point<=0) price_per_point = 1.0; // fallback
   double risk_per_lot = (sl_dist/point) * price_per_point;
   double volume = NormalizeDouble(risk_amount / risk_per_lot,2);
   // clamp volume to allowed min/max
   double minLot = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(minLot==0) minLot=0.01;
   if(volume < minLot) volume = minLot;
   if(volume > maxLot) volume = maxLot;
   // normalize to step
   volume = MathFloor(volume/lotStep)*lotStep;

   // Determine side
   ENUM_ORDER_TYPE orderType = (h1_trend==1)?ORDER_TYPE_BUY:ORDER_TYPE_SELL;

   // Build trade request
   MqlTradeRequest req; MqlTradeResult res; MqlTradeCheckResult check;
   ZeroMemory(req); ZeroMemory(res);
   req.action = TRADE_ACTION_DEAL;
   req.symbol = _Symbol;
   req.volume = volume;
   req.type = (orderType==ORDER_TYPE_BUY)?ORDER_TYPE_BUY:ORDER_TYPE_SELL;
   req.price = (orderType==ORDER_TYPE_BUY)?SymbolInfoDouble(_Symbol,SYMBOL_ASK):SymbolInfoDouble(_Symbol,SYMBOL_BID);

   double slPrice, tpPrice;
   if(orderType==ORDER_TYPE_BUY){
      slPrice = req.price - sl_dist;
      tpPrice = req.price + tp1;
   } else {
      slPrice = req.price + sl_dist;
      tpPrice = req.price - tp1;
   }
   // add small buffer
   slPrice = NormalizeDouble(slPrice, (int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS));
   tpPrice = NormalizeDouble(tpPrice, (int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS));
   req.sl = slPrice; req.tp = tpPrice;
   req.deviation = 10;
   req.magic = 20250921;
   req.type_filling = ORDER_FILLING_RETURN;

   if(!OrderCheck(req,check)){
      Print("OrderCheck failed: ",check.comment);
      return;
   }

   if(!OrderSend(req,res)){
      Print("OrderSend failed: ",GetLastError()," ",res.comment);
   } else {
      Print("Trade placed: ",(orderType==ORDER_TYPE_BUY?"BUY":"SELL")," vol=",DoubleToString(volume,2)," SL=",DoubleToString(req.sl,_Digits)," TP=",DoubleToString(req.tp,_Digits));
   }
}

//---------------- helper functions ----------------

double MA(string symbol,ENUM_TIMEFRAMES tf,int period,int shift){
   return iMA(symbol,tf,period,0,MODE_SMA,PRICE_CLOSE,shift);
}

double ATR_VAL(string symbol,ENUM_TIMEFRAMES tf,int period,int shift){
   return iATR(symbol,tf,period,shift);
}

bool OrderCheck(const MqlTradeRequest &request, MqlTradeCheckResult &result){
   // simple wrapper for trade check
   if(!OrderCheck(request,result)) return false;
   return true;
}