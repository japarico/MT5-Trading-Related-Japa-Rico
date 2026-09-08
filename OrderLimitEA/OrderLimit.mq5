//+------------------------------------------------------------------+
//|                              Order Manager EA with Stop Loss.mq5 |
//|                                         Copyright 2026, japarico |
//+------------------------------------------------------------------+
#property strict

#include <Trade\Trade.mqh>

input double lotSize=0.01;       // Lot Size
input int ftp=1000;              // Fake Take Profit
input int fsl=1000;              // Fake Stop Loss
input int ttp=150;               // True Take Profit
input int tsl=100;               // True Stop Loss
input int lip=100;               // Lock In Points
input int alip=120;              // Activate Lock In Points after X Points in Profit
input bool buttons=true;         // Use Buttons
input int xoff=150;              // Buttons X Offset
input int yoff=100;              // Buttons Y Offset
input int gmt=3;                 // GMT Offset
input bool DrawLines=false;      // Draw Alert Lines
input string prefix="";           // Symbol Prefix
input string suffix="";          // Symbol Suffix

input bool Alerts=true;
input double InpMaxLossPercent=5.0; // Default Max Account Loss (%)

datetime curtime, prevtime;
int dig=1;
CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(buttons)
     {
      //Lot Size Selector
      ObjectCreate(0,"LotMinus",OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,"LotMinus",OBJPROP_COLOR,clrBlack);
      ObjectSetInteger(0,"LotMinus",OBJPROP_BGCOLOR,clrGray);
      ObjectSetInteger(0,"LotMinus",OBJPROP_CORNER,CORNER_RIGHT_LOWER);
      ObjectSetInteger(0,"LotMinus",OBJPROP_XDISTANCE,xoff-15);
      ObjectSetInteger(0,"LotMinus",OBJPROP_YDISTANCE,yoff+45);
      ObjectSetInteger(0,"LotMinus",OBJPROP_XSIZE,25);
      ObjectSetInteger(0,"LotMinus",OBJPROP_YSIZE,20);
      ObjectSetInteger(0,"LotMinus",OBJPROP_STATE,0);
      ObjectSetString(0,"LotMinus",OBJPROP_FONT,"Arial");
      ObjectSetString(0,"LotMinus",OBJPROP_TEXT,"-");
      ObjectSetInteger(0,"LotMinus",OBJPROP_FONTSIZE,10);
      ObjectSetInteger(0,"LotMinus",OBJPROP_SELECTABLE,0);

      ObjectCreate(0,"LotSize",OBJ_EDIT,0,0,0);
      ObjectSetInteger(0,"LotSize",OBJPROP_COLOR,clrBlack);
      ObjectSetInteger(0,"LotSize",OBJPROP_BGCOLOR,clrWhite);
      ObjectSetInteger(0,"LotSize",OBJPROP_CORNER,CORNER_RIGHT_LOWER);
      ObjectSetInteger(0,"LotSize",OBJPROP_XDISTANCE,xoff-40);
      ObjectSetInteger(0,"LotSize",OBJPROP_YDISTANCE,yoff+45);
      ObjectSetInteger(0,"LotSize",OBJPROP_XSIZE,50);
      ObjectSetInteger(0,"LotSize",OBJPROP_YSIZE,20);
      ObjectSetString(0,"LotSize",OBJPROP_FONT,"Arial");
      ObjectSetString(0,"LotSize",OBJPROP_TEXT,DoubleToString(lotSize,2));
      ObjectSetInteger(0,"LotSize",OBJPROP_FONTSIZE,10);
      ObjectSetInteger(0,"LotSize",OBJPROP_READONLY,false);

      ObjectCreate(0,"LotPlus",OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,"LotPlus",OBJPROP_COLOR,clrBlack);
      ObjectSetInteger(0,"LotPlus",OBJPROP_BGCOLOR,clrGray);
      ObjectSetInteger(0,"LotPlus",OBJPROP_CORNER,CORNER_RIGHT_LOWER);
      ObjectSetInteger(0,"LotPlus",OBJPROP_XDISTANCE,xoff-80);
      ObjectSetInteger(0,"LotPlus",OBJPROP_YDISTANCE,yoff+45);
      ObjectSetInteger(0,"LotPlus",OBJPROP_XSIZE,25);
      ObjectSetInteger(0,"LotPlus",OBJPROP_YSIZE,20);
      ObjectSetInteger(0,"LotPlus",OBJPROP_STATE,0);
      ObjectSetString(0,"LotPlus",OBJPROP_FONT,"Arial");
      ObjectSetString(0,"LotPlus",OBJPROP_TEXT,"+");
      ObjectSetInteger(0,"LotPlus",OBJPROP_FONTSIZE,10);
      ObjectSetInteger(0,"LotPlus",OBJPROP_SELECTABLE,0);

      //--- NEW PANEL CONTROLS: Max Loss % Selector ---
      ObjectCreate(0,"MaxLossLabel",OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,"MaxLossLabel",OBJPROP_COLOR,clrWhite);
      ObjectSetInteger(0,"MaxLossLabel",OBJPROP_CORNER,CORNER_RIGHT_LOWER);
      ObjectSetInteger(0,"MaxLossLabel",OBJPROP_XDISTANCE,xoff+40);
      ObjectSetInteger(0,"MaxLossLabel",OBJPROP_YDISTANCE,yoff+70);
      ObjectSetString(0,"MaxLossLabel",OBJPROP_FONT,"Arial");
      ObjectSetString(0,"MaxLossLabel",OBJPROP_TEXT,"Max Loss %:");
      ObjectSetInteger(0,"MaxLossLabel",OBJPROP_FONTSIZE,9);

      ObjectCreate(0,"MaxLossSize",OBJ_EDIT,0,0,0);
      ObjectSetInteger(0,"MaxLossSize",OBJPROP_COLOR,clrBlack);
      ObjectSetInteger(0,"MaxLossSize",OBJPROP_BGCOLOR,clrWhite);
      ObjectSetInteger(0,"MaxLossSize",OBJPROP_CORNER,CORNER_RIGHT_LOWER);
      ObjectSetInteger(0,"MaxLossSize",OBJPROP_XDISTANCE,xoff-40);
      ObjectSetInteger(0,"MaxLossSize",OBJPROP_YDISTANCE,yoff+68);
      ObjectSetInteger(0,"MaxLossSize",OBJPROP_XSIZE,50);
      ObjectSetInteger(0,"MaxLossSize",OBJPROP_YSIZE,20);
      ObjectSetString(0,"MaxLossSize",OBJPROP_FONT,"Arial");
      ObjectSetString(0,"MaxLossSize",OBJPROP_TEXT,DoubleToString(InpMaxLossPercent,1));
      ObjectSetInteger(0,"MaxLossSize",OBJPROP_FONTSIZE,10);
      ObjectSetInteger(0,"MaxLossSize",OBJPROP_READONLY,false);
      //-----------------------------------------------

      //Buys
      ObjectCreate(0,"BuyMarket",OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,"BuyMarket",OBJPROP_COLOR,clrBlack);
      ObjectSetInteger(0,"BuyMarket",OBJPROP_BGCOLOR,clrLime);
      ObjectSetInteger(0,"BuyMarket",OBJPROP_CORNER,CORNER_RIGHT_LOWER);
      ObjectSetInteger(0,"BuyMarket",OBJPROP_XDISTANCE,xoff);
      ObjectSetInteger(0,"BuyMarket",OBJPROP_YDISTANCE,yoff);
      ObjectSetInteger(0,"BuyMarket",OBJPROP_XSIZE,50);
      ObjectSetInteger(0,"BuyMarket",OBJPROP_YSIZE,15);
      ObjectSetInteger(0,"BuyMarket",OBJPROP_STATE,0);
      ObjectSetString(0,"BuyMarket",OBJPROP_FONT,"Arial");
      ObjectSetString(0,"BuyMarket",OBJPROP_TEXT,"Buy");
      ObjectSetInteger(0,"BuyMarket",OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,"BuyMarket",OBJPROP_SELECTABLE,0);

      //Sells
      ObjectCreate(0,"SellMarket",OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,"SellMarket",OBJPROP_COLOR,clrBlack);
      ObjectSetInteger(0,"SellMarket",OBJPROP_BGCOLOR,clrRed);
      ObjectSetInteger(0,"SellMarket",OBJPROP_CORNER,CORNER_RIGHT_LOWER);
      ObjectSetInteger(0,"SellMarket",OBJPROP_XDISTANCE,xoff);
      ObjectSetInteger(0,"SellMarket",OBJPROP_YDISTANCE,yoff-20);
      ObjectSetInteger(0,"SellMarket",OBJPROP_XSIZE,50);
      ObjectSetInteger(0,"SellMarket",OBJPROP_YSIZE,15);
      ObjectSetInteger(0,"SellMarket",OBJPROP_STATE,0);
      ObjectSetString(0,"SellMarket",OBJPROP_FONT,"Arial");
      ObjectSetString(0,"SellMarket",OBJPROP_TEXT,"Sell");
      ObjectSetInteger(0,"SellMarket",OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,"SellMarket",OBJPROP_SELECTABLE,0);

      ObjectCreate(0,"CloseP",OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,"CloseP",OBJPROP_COLOR,clrBlack);
      ObjectSetInteger(0,"CloseP",OBJPROP_BGCOLOR,clrOrange);
      ObjectSetInteger(0,"CloseP",OBJPROP_CORNER,CORNER_RIGHT_LOWER);
      ObjectSetInteger(0,"CloseP",OBJPROP_XDISTANCE,xoff);
      ObjectSetInteger(0,"CloseP",OBJPROP_YDISTANCE,yoff+20);
      ObjectSetInteger(0,"CloseP",OBJPROP_XSIZE,125);
      ObjectSetInteger(0,"CloseP",OBJPROP_YSIZE,15);
      ObjectSetInteger(0,"CloseP",OBJPROP_STATE,0);
      ObjectSetString(0,"CloseP",OBJPROP_FONT,"Arial");
      ObjectSetString(0,"CloseP",OBJPROP_TEXT,"Close Profit");
      ObjectSetInteger(0,"CloseP",OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,"CloseP",OBJPROP_SELECTABLE,0);

      ObjectCreate(0,"SetBE",OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,"SetBE",OBJPROP_COLOR,clrBlack);
      ObjectSetInteger(0,"SetBE",OBJPROP_BGCOLOR,clrDodgerBlue);
      ObjectSetInteger(0,"SetBE",OBJPROP_CORNER,CORNER_RIGHT_LOWER);
      ObjectSetInteger(0,"SetBE",OBJPROP_XDISTANCE,xoff);
      ObjectSetInteger(0,"SetBE",OBJPROP_YDISTANCE,yoff-60);
      ObjectSetInteger(0,"SetBE",OBJPROP_XSIZE,125);
      ObjectSetInteger(0,"SetBE",OBJPROP_YSIZE,15);
      ObjectSetInteger(0,"SetBE",OBJPROP_STATE,0);
      ObjectSetString(0,"SetBE",OBJPROP_FONT,"Arial");
      ObjectSetString(0,"SetBE",OBJPROP_TEXT,"Set to Break Even");
      ObjectSetInteger(0,"SetBE",OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,"SetBE",OBJPROP_SELECTABLE,0);

      ObjectCreate(0,"CloseA",OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,"CloseA",OBJPROP_COLOR,clrBlack);
      ObjectSetInteger(0,"CloseA",OBJPROP_BGCOLOR,clrOrange);
      ObjectSetInteger(0,"CloseA",OBJPROP_CORNER,CORNER_RIGHT_LOWER);
      ObjectSetInteger(0,"CloseA",OBJPROP_XDISTANCE,xoff);
      ObjectSetInteger(0,"CloseA",OBJPROP_YDISTANCE,yoff-40);
      ObjectSetInteger(0,"CloseA",OBJPROP_XSIZE,125);
      ObjectSetInteger(0,"CloseA",OBJPROP_YSIZE,15);
      ObjectSetInteger(0,"CloseA",OBJPROP_STATE,0);
      ObjectSetString(0,"CloseA",OBJPROP_FONT,"Arial");
      ObjectSetString(0,"CloseA",OBJPROP_TEXT,"Close All");
      ObjectSetInteger(0,"CloseA",OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,"CloseA",OBJPROP_SELECTABLE,0);
     }
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDelete(0,"LotMinus");
   ObjectDelete(0,"LotSize");
   ObjectDelete(0,"LotPlus");
   ObjectDelete(0,"MaxLossLabel");
   ObjectDelete(0,"MaxLossSize");
   ObjectDelete(0,"BuyMarket");
   ObjectDelete(0,"SellMarket");
   ObjectDelete(0,"CloseP");
   ObjectDelete(0,"CloseA");
   ObjectDelete(0,"SetBE");
  }

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      // --- BUY BUTTON ---
      if(sparam == "BuyMarket")
        {
         double currentLotSize = StringToDouble(ObjectGetString(0,"LotSize",OBJPROP_TEXT));
         double ask_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         if(trade.Buy(currentLotSize, _Symbol, ask_price, 0, 0, "Order Manager"))
           {
            // Success
           }
         else
            Print("OrderSend Buy Error: ", GetLastError());

         ObjectSetInteger(0,"BuyMarket",OBJPROP_STATE,0);
         ChartRedraw();
        }

      // --- SELL BUTTON ---
      if(sparam == "SellMarket")
        {
         double currentLotSize = StringToDouble(ObjectGetString(0,"LotSize",OBJPROP_TEXT));
         double bid_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         if(trade.Sell(currentLotSize, _Symbol, bid_price, 0, 0, "Order Manager"))
           {
            // Success
           }
         else
            Print("OrderSend Sell Error: ", GetLastError());

         ObjectSetInteger(0,"SellMarket",OBJPROP_STATE,0);
         ChartRedraw();
        }

      // --- LOT MINUS ---
      if(sparam == "LotMinus")
        {
         double currentLot = StringToDouble(ObjectGetString(0,"LotSize",OBJPROP_TEXT));
         currentLot = MathMax(0.01, currentLot - 0.01);
         ObjectSetString(0,"LotSize",OBJPROP_TEXT,DoubleToString(currentLot,2));
         ObjectSetInteger(0,"LotMinus",OBJPROP_STATE,0);
         ChartRedraw();
        }

      // --- LOT PLUS ---
      if(sparam == "LotPlus")
        {
         double currentLot = StringToDouble(ObjectGetString(0,"LotSize",OBJPROP_TEXT));
         currentLot = currentLot + 0.01;
         ObjectSetString(0,"LotSize",OBJPROP_TEXT,DoubleToString(currentLot,2));
         ObjectSetInteger(0,"LotPlus",OBJPROP_STATE,0);
         ChartRedraw();
        }

      // --- CLOSE PROFIT ---
      if(sparam == "CloseP")
        {
         for(int i=PositionsTotal()-1;i>=0;i--)
           {
            ulong ticket = PositionGetTicket(i);
            if(ticket <= 0) continue;
            if(!PositionSelectByTicket(ticket)) continue;
            if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

            double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            if(profit >= 0)
              {
               if(!trade.PositionClose(ticket))
                  Print("PositionClose Error: ", GetLastError());
              }
           }
         ObjectSetInteger(0,"CloseP",OBJPROP_STATE,0);
         ChartRedraw();
        }

      // --- SET BREAK EVEN ---
      if(sparam == "SetBE")
        {
         datetime last_open_time = 0;
         double last_open_price = 0;
         ulong last_order_ticket = 0;

         for(int i=PositionsTotal()-1; i>=0; i--)
           {
            ulong ticket = PositionGetTicket(i);
            if(ticket <= 0) continue;
            if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol)
              {
               if((datetime)PositionGetInteger(POSITION_TIME) > last_open_time)
                 {
                  last_open_time = (datetime)PositionGetInteger(POSITION_TIME);
                  last_open_price = PositionGetDouble(POSITION_PRICE_OPEN);
                  last_order_ticket = ticket;
                 }
              }
           }

         if(last_order_ticket > 0)
           {
            for(int j=PositionsTotal()-1; j>=0; j--)
              {
               ulong ticket = PositionGetTicket(j);
               if(ticket <= 0) continue;
               if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol)
                 {
                  long type = PositionGetInteger(POSITION_TYPE);
                  double tp = PositionGetDouble(POSITION_TP);
                  double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                  double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

                  if(type == POSITION_TYPE_BUY && last_open_price < ask)
                    {
                     if(!trade.PositionModify(ticket, last_open_price, tp))
                        Print("PositionModify Error: ", GetLastError());
                    }
                  else if(type == POSITION_TYPE_SELL && last_open_price > bid)
                    {
                     if(!trade.PositionModify(ticket, last_open_price, tp))
                        Print("PositionModify Error: ", GetLastError());
                    }
                 }
              }
           }
         ObjectSetInteger(0,"SetBE",OBJPROP_STATE,0);
         ChartRedraw();
        }

      // --- CLOSE ALL ---
      if(sparam == "CloseA")
        {
         ForceCloseAll();
         ObjectSetInteger(0,"CloseA",OBJPROP_STATE,0);
         ChartRedraw();
        }
     }
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   CheckAndCloseOnMaxLoss();

   if(_Digits==3 || _Digits==5) dig=10;
   else dig=1;

   CheckLines();
   DeleteOldLines();

   if(PositionsTotal()>0)
     {
      for(int o=PositionsTotal()-1;o>=0;o--)
        {
         ulong ticket = PositionGetTicket(o);
         if(ticket <= 0) continue;
         if(PositionSelectByTicket(ticket))
           {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol)
              {
               double thesl = ObjectGetDouble(0, IntegerToString(ticket) + " SL", OBJPROP_PRICE, 0);
               double thetp = ObjectGetDouble(0, IntegerToString(ticket) + " TP", OBJPROP_PRICE, 0);
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Automatic Account Drawdown Protection Logic                      |
//+------------------------------------------------------------------+
void CheckAndCloseOnMaxLoss()
{
   double acc_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(acc_balance <= 0) return;

   double maxLossLimit = StringToDouble(ObjectGetString(0, "MaxLossSize", OBJPROP_TEXT));
   if(maxLossLimit <= 0) maxLossLimit = InpMaxLossPercent;

   double acc_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double currentLossPercent = ((acc_balance - acc_equity) / acc_balance) * 100.0;

   if(currentLossPercent >= maxLossLimit)
   {
      Alert("CRITICAL: Max account loss limit breached! Liquidation triggered.");
      ForceCloseAll();
   }
}

//+------------------------------------------------------------------+
//| Loop through all open positions on the account and close them   |
//+------------------------------------------------------------------+
void ForceCloseAll()
{
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionSelectByTicket(ticket))
        {
         if(!trade.PositionClose(ticket))
           {
            Print("ForceCloseAll PositionClose Error: ", GetLastError());
           }
        }
     }

   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket <= 0) continue;
      if(OrderSelect(ticket))
        {
         if(!trade.OrderDelete(ticket))
           {
            Print("ForceCloseAll OrderDelete Error: ", GetLastError());
           }
        }
     }
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Placeholder structural stubs for incomplete custom logic functions|
//+------------------------------------------------------------------+
void CheckLines()
{
   // Add custom manual line checking logic here if applicable
}

void DeleteOldLines()
{
   // Add clean up logic for expired lines here if applicable
}
//+------------------------------------------------------------------+