//+-------------------------------------------------------------------------+
//|                                                           BBAHAMAX1.mq4 |
//|                                           Copyright 2017, Stephan Benik |
//|                                                                         |
//|    BOLLINGER BAnds Heikin Ashi Moving Average CROSS System 1            |
//|  Grundsatz: BB wird über Heikin Ahsi Werte berechnet                    |
//|  LONG Kerze schließt über BB MA und Vorgänger-Kerze schließt unterhalb  |
//|       MA > Gekreuzt                                                     |
//|  ENTRY am Close der letzten Kerze                                       |
//|  SHORT umgekehrt                                                        |
//|  SL     Unter dem Tief der letzten vier Kerzen + 1 Pip, bzw. umgekehrt  |
//|         bei SHORT                                                       |
//|  TSL    LONG Max LOW der letzten 4 Kerzen - 1 Pip                       |
//|         SHORT Max HIGH der letzten 4 Kerzen + 1 Pip                     |
//+-------------------------------------------------------------------------+
#property copyright "Copyright 2017, Stephan Benik"
#property link      ""
#property version   "1.00"
#property strict
// globale, änderbare Variablen
// extern double TPLong          = 0;  // TakeProfit Long in Punkten
// extern double TPShort         = 0;  // TakeProfit Short in Punkten
//extern double SLLong          = 0.2;  // SL Buffer Long in %     (1.04)
// extern double SLShort         = 0.2;  // SL Buffer Short in %    (1.04)
extern bool   Dynamik         = false; // Anzahl CFDs nach Budget
extern double AnzahlCFD       = 1;    // Anzahl der CFDs (fest)
extern int MaximalAnzahlCFD   = 50;   // Max. Anz. CFD bei Dynamik
extern double RisikoWert      = 5;    // Risikowert (%) auf Gesamtbudget
extern int BBPeriod           = 20;   // BollBand Periode
extern int BBAbweichung       = 2;    // BollBand Abweichung
extern int BBShift            = 0;    // BollBand Versatz
extern double TSLPuffer       = 500;  // SLPuffer in Pips
extern double SLPuffer        = 200;  // SLPuffer in Pips
extern int HAHLoC             = 1;    // 1 = High/Low, 3 = Close 
extern ENUM_TIMEFRAMES TFOpt  = PERIOD_M1; // Timeframe
// extern double CrossPufferLONG  = 300;  // Cross-Puffer L in Pips
// extern double CrossPufferSHORT = 300;  // Cross-Puffer S in Pips
extern int HandelvonHH        = 6;    // Handel von HH
// extern int HandelvonMM        = 30;    // Handelspause MM ab
extern int HandelbisHH        = 18;    // Handel bis HH
// extern int HandelbisMM        = 0;    // Handelspause MM bis
extern int MagicNumber        = 197471; // Magic Number
extern string EAName          = "BBAHAMAX1"; // EA-Name für Kommentar
extern bool Overnight         = false;  // Pos. über Nacht halten?
extern bool GegenrichtungSchliessen = true; // Signal schließt Gegenrichtung
// extern int ATRPeriode         = 8;    // ATR Periode

// globale, nicht änderbare Variabeln
datetime PeriodenStartZeit;
bool NeuePeriodeBegonnen;
// bool LTrade = false;
// bool STrade = false;
double stopl,takeprofit,Lot,Price_Cls,OpenPrice,StopLoss,TakeProfit; // 
int LOrder,SOrder,Ticket,x,STShift; 
double AnzahlLots;
string Text = "unbelegt";
bool   TrendWechsel = false;
string SuperTrend = "UP";
double b4plusdi, b4minusdi, nowplusdi, nowminusdi;
string Trade;


// globale Funktionen

int Kommentare(string KommentarZeile1,
               string KommentarZeile2,
               string KommentarZeile3,
               string KommentarZeile4){
ObjectCreate("comment_zeile1",OBJ_LABEL,0,0,0);
   ObjectSet("comment_zeile1",OBJPROP_XDISTANCE,10);
   ObjectSet("comment_zeile1",OBJPROP_YDISTANCE,20);
   ObjectSetText("comment_zeile1",KommentarZeile1,11,"Arial",White);

   ObjectCreate("comment_zeile2",OBJ_LABEL,0,0,0);
   ObjectSet("comment_zeile2",OBJPROP_XDISTANCE,10);
   ObjectSet("comment_zeile2",OBJPROP_YDISTANCE,40);
   ObjectSetText("comment_zeile2",KommentarZeile2,11,"Arial",White);

   ObjectCreate("comment_zeile3",OBJ_LABEL,0,0,0);
   ObjectSet("comment_zeile3",OBJPROP_XDISTANCE,10);
   ObjectSet("comment_zeile3",OBJPROP_YDISTANCE,60);
   ObjectSetText("comment_zeile3",KommentarZeile3,11,"Arial",White);

   ObjectCreate("comment_zeile4",OBJ_LABEL,0,0,0);
   ObjectSet("comment_zeile4",OBJPROP_XDISTANCE,10);
   ObjectSet("comment_zeile4",OBJPROP_YDISTANCE,80);
   ObjectSetText("comment_zeile4",KommentarZeile4,11,"Arial",White);
   WindowRedraw();
   return(0);
}

int Kommentare_loeschen(){
   ObjectDelete("comment_zeile1");
   ObjectDelete("comment_zeile2");
   ObjectDelete("comment_zeile3");
   ObjectDelete("comment_zeile4");
   WindowRedraw();
   return(0);   
}

 // Heiken Ashi Signale
double GetHA(int tf, int param, int shift)
   { return(iCustom(NULL,tf,"Heiken Ashi",param,shift));}
   
double SLLast4(string Richtung){
   if(Richtung == "LONG"){
     double SL = 0;
     for(int x1 = 1;x1 < 6; x1++){
       if(GetHA(TFOpt,3,x1) > SL){
            SL = GetHA(TFOpt,2,x1) - (TSLPuffer*Point);
       }
     } 
     Print("SL: ",SL);
     return(SL);
   }
   if(Richtung == "SHORT"){
     double SL = 999999;
     for(int x2 = 1;x2 < 6; x2++){
       if(GetHA(TFOpt,3,x2) < SL){
            SL = GetHA(TFOpt,2,x2)+ (TSLPuffer*Point);
       }
     } 
     Print("SL: ",SL);
     return(SL);
   }
   return(0);
}

int LongOrder(){

stopl      = SLLast4("LONG");
takeprofit = 0; // (TPLong == 0)? 0 : (Ask + TPLong);

/* if(Dynamik){ AnzahlLots = floor((AccountBalance() * RisikoWert / 100) / (Ask * SLLong / 100));
             if(AnzahlLots > MaximalAnzahlCFD){ AnzahlLots = MaximalAnzahlCFD;};
} else {AnzahlLots = AnzahlCFD;}
*/
AnzahlLots = AnzahlCFD;
if(AnzahlLots < 0){Alert("Kein Trade möglich. Anzahl Lots mit dem angegebenen Risiko < = 0.");
                    return(0);
}
   LOrder = OrderSend(Symbol(),OP_BUY,AnzahlLots,Ask,10,stopl,takeprofit,EAName,MagicNumber,0,Green);
   if(LOrder != -1){
      Trade = "LONG";
      PlaySound("bulup.wav");
   } else {Print("Order-Fehler: ",GetLastError());}

   return(0);
}

int ShortOrder(){

stopl      = SLLast4("SHORT");
takeprofit = 0; // (TPShort == 0) ? 0 : (Bid - TPShort);


/* if(Dynamik){ AnzahlLots = floor((AccountBalance() * RisikoWert / 100) / (Bid * SLShort /100));
             if(AnzahlLots > MaximalAnzahlCFD){ AnzahlLots = MaximalAnzahlCFD;};
} else {AnzahlLots = AnzahlCFD;}
*/
AnzahlLots = AnzahlCFD;
if(AnzahlLots <= 0){Alert("Kein Trade möglich. Anzahl Lots mit dem angegebenen Risiko < = 0");
                    return(0);
}
   SOrder = OrderSend(Symbol(),OP_SELL,AnzahlLots,Bid,10,stopl,takeprofit,EAName,MagicNumber,0,Red);
   if(SOrder != -1){
      Trade = "SHORT";
      PlaySound("bulup.wav");
   } else {Print("Order-Fehler: ",GetLastError());}
       
   return(0);
}

int OffeneOrderSchliessen(){
    
   string Symb=Symbol();                        // Symbol
   double Dist=1000000.0;                       // Presetting
   int Real_Order=-1;                           // No market orders yet
   double Win_Price=WindowPriceOnDropped();     // The script is dropped here

//-------------------------------------------------------------------------------- 2 --
   for(int i=1; i<=OrdersTotal(); i++)          // Order searching cycle
     {
      if (OrderSelect(i-1,SELECT_BY_POS)==true) // If the next is available
        {                                       // Order analysis:
         //----------------------------------------------------------------------- 3 --
         if (OrderSymbol()!= Symb || OrderMagicNumber() != MagicNumber) continue;    // Symbol is not ours
         int Tip=OrderType();                   // Order type
         if (Tip>1) continue;                   // Pending order  
         //----------------------------------------------------------------------- 4 --
         double Price=OrderOpenPrice();         // Order price
         if (NormalizeDouble(MathAbs(Price-Win_Price),Digits)< //Selection
            NormalizeDouble(Dist,Digits))       // of the closest order       
           {
            Dist=MathAbs(Price-Win_Price);      // New value
            Real_Order=Tip;                     // Market order available
            Ticket=OrderTicket();           // Order ticket
            Lot=OrderLots();             // Amount of lots
           }
         //----------------------------------------------------------------------- 5 --
        }                                       //End of order analysis
     }                                          //End of order searching
//-------------------------------------------------------------------------------- 6 --
   while(true)                                  // Order closing cycle
     {
      if (Real_Order==-1)                       // If no market orders available
        {
         Print("Keine offenen Orders für ",Symb," vorhanden");
         break;                                 // Exit closing cycle        
        }
      //-------------------------------------------------------------------------- 7 --
      switch(Real_Order)                        // By order type
        {
         case 0: 
            {
            Price_Cls=Bid;          // Order Buy
            Text="LONG Order ";                 // Text for Buy
            }
            break;                              // Из switch
         case 1: 
            {
            Price_Cls=Ask;                 // Order Sell
            Text="SHORT Order ";                       // Text for Sell
            }
        }
      Print("Versuche ",Text," ",Ticket," zu schließen. Warte auf Antwort...");
      bool Ans=OrderClose(Ticket,Lot,Price_Cls,2);// Order closing
      //-------------------------------------------------------------------------- 8 --
      if (Ans==true)                            // Got it! :)
        {
         Print (Text," geschlossen ",Ticket);
         Trade = "FLAT";
         break;                                 // Exit closing cycle
        }
      //-------------------------------------------------------------------------- 9 --
      int Error=GetLastError();                 // Failed :(
      switch(Error)                             // Overcomable errors
        {
         case 135:
            { 
            Print("The price has changed. Retrying..");
            RefreshRates();                     // Update data
            }
            continue;                           // At the next iteration
         case 136:
            {
            Print("No prices. Waiting for a new tick..");
            while(RefreshRates()==false)        // To the new tick
               Sleep(1);                        // Cycle sleep
            }
            continue;                           // At the next iteration
         case 146:
            {
            Print("Trading subsystem is busy. Retrying..");
            Sleep(500);                         // Simple solution
            RefreshRates();                     // Update data
            }
            continue;                           // At the next iteration
        }
      switch(Error)                             // Critical errors
        {
         case 2 : {Print("Common error.");}
            break;                              // Exit 'switch'
         case 5 : {Print("Old version of the client terminal.");}
            break;                              // Exit 'switch'
         case 64: {Print("Account is blocked.");}
            break;                              // Exit 'switch'
         case 133:{Print("Trading is prohibited");}
            break;                              // Exit 'switch'
         default: {Print("Occurred error ",Error);}//Other alternatives   
        }
      break;                                    // Exit closing cycle
     }
   return(0);                                      // Exit OffeneOrderSchliessen()
  }

void TrailingAlls()
  {

//----
   double stopcrnt;
   double stopcal;
   int trade;
   int trades=OrdersTotal();
   double profitcalc;
   for(trade=0;trade<trades;trade++)
     {
      OrderSelect(trade,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber() == MagicNumber)
         {
         //continue;
         //LONG
         if(OrderType()==OP_BUY)
           { 
            // Prüfen, ob oberes BB erreicht wurde, dann SL unter letzte Kerze, sonst normaler TSL
            stopcrnt=OrderStopLoss();
            if(GetHA(TFOpt,HAHLoC,1) > iBands(NULL,TFOpt,BBPeriod,BBAbweichung,BBShift,PRICE_CLOSE,MODE_UPPER,1)){
            
              stopcal = GetHA(TFOpt,0,1) - (SLPuffer * Point);
              Print("Passe SL LONG auf ",stopcal," an. (",SLPuffer," Pips)");
            } else {stopcal = SLLast4("LONG");
                    Print("Passe SL LONG auf ",stopcal," an. (",TSLPuffer," Pips)");}
            
            profitcalc=OrderTakeProfit()+(TakeProfit*Point);
            if (stopcrnt==0)
              {
               OrderModify(OrderTicket(),OrderOpenPrice(),stopcal,profitcalc,0,Blue);
              }
            else
               if(stopcal>stopcrnt)
                 {
                  OrderModify(OrderTicket(),OrderOpenPrice(),stopcal,profitcalc,0,Blue);
                 }
            }
         }//LONG
         //Shrt
         if(OrderType()==OP_SELL)
           {
            stopcrnt=OrderStopLoss();
            
            // Prüfen, ob unteres BB erreicht wurde, dann SL über letzte Kerze, sonst normaler TSL
            
            if(GetHA(TFOpt,HAHLoC,1) < iBands(NULL,TFOpt,BBPeriod,BBAbweichung,BBShift,PRICE_CLOSE,MODE_LOWER,1)){
            
              stopcal = GetHA(TFOpt,0,1) + (SLPuffer * Point);
              Print("Passe SL SHORT auf ",stopcal," an. (",SLPuffer," Pips)");
            
            } else {stopcal = SLLast4("LONG");
                    Print("Passe SL SHORT auf ",stopcal," an. (",TSLPuffer," Pips)");}
            
            profitcalc=OrderTakeProfit()-(TakeProfit*Point);
            
            if (stopcrnt==0)
              {
               OrderModify(OrderTicket(),OrderOpenPrice(),stopcal,profitcalc,0,Red);
              }
            else
               if(stopcal<stopcrnt)
                 {
                  OrderModify(OrderTicket(),OrderOpenPrice(),stopcal,profitcalc,0,Red);
                 }
           }
      }
  }//Exit Trailing
  
void SLBEsetzen()
  {
/*
   double stopcrnt;
   double stopcal;
   int trade;
   int trades=OrdersTotal();
   double profitcalc;
   for(trade=0;trade<trades;trade++)
     {
      OrderSelect(trade,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber() == MagicNumber)
         {
         //LONG
         if(OrderType()==OP_BUY)
           { 
            stopcrnt=OrderStopLoss(); // Noch abfragen, ob SL schon auf BE gesetzt wurde
            stopcal= OrderOpenPrice() + (SLBE*Point);
            // profitcalc=OrderTakeProfit()+(TakeProfit*Point);
            if ((Bid + (SLBESW*Point)) > OrderOpenPrice())
              {
               OrderModify(OrderTicket(),OrderOpenPrice(),stopcal,0,0,Blue);
              }
         }//LONG
         //Shrt
         if(OrderType()==OP_SELL)
           {
            stopcrnt=OrderStopLoss();
            stopcal= OrderOpenPrice() - (SLBE*Point);
            profitcalc=OrderTakeProfit()-(TakeProfit*Point);
            if (stopcrnt==0)
              {
               OrderModify(OrderTicket(),OrderOpenPrice(),stopcal,profitcalc,0,Red);
              }
            else
               if(stopcal<stopcrnt)
                 {
                  OrderModify(OrderTicket(),OrderOpenPrice(),stopcal,profitcalc,0,Red);
                 }
           }
      }
      }
      */
  }//Exit SLBEsetzen
  
int OrdersSuchen(int Richtung){
   int trade;
   int AnzahlOrders = 0;
   
   Print(OrdersTotal()," Orders insgesamt"); 
 
   for(int i=1; i<=OrdersTotal(); i++)          // Order searching cycle
     {
      if (OrderSelect(i-1,SELECT_BY_POS)==true) // If the next is available
        {  
        if(Richtung == 1){                                     
         if (OrderSymbol()== Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_BUY){
         
            OffeneOrderSchliessen();
            AnzahlOrders++;
            }
         }
        if(Richtung == 2){                                     
         if (OrderSymbol()== Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_SELL){
         
            OffeneOrderSchliessen();
            AnzahlOrders++;
            }
         }   
        }   
      }
   Print(AnzahlOrders," ",(Richtung == 1)?("Buy"):("Sell"),"-Orders geschlossen");  
   return(AnzahlOrders);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   PeriodenStartZeit = Time[0]; // Einmaliges Setzen des Zeitstempels
   Kommentare_loeschen();
   
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
// Auf Periodenstart prüfen
   if(PeriodenStartZeit != Time[0]){
      NeuePeriodeBegonnen = true;
     // PeriodenNullsetzen();
      PeriodenStartZeit = Time[0];
   } else { NeuePeriodeBegonnen = false; }
   
   if(NeuePeriodeBegonnen == true){
   
      if(TimeHour(TimeCurrent()) >= HandelvonHH &&
         TimeHour(TimeCurrent()) <  HandelbisHH){
         // Handelsbedingungen prüfen
         // auf BB-MA-Cross prüfen "Letzte Kerze schließt oberhalb des MA und vorletzte Kerze schließt unterhalb des MA" 


         
         if(GetHA(TFOpt,3,1) > iBands(NULL,TFOpt,BBPeriod,BBAbweichung,BBShift,PRICE_CLOSE,MODE_MAIN,1) &&
            GetHA(TFOpt,3,2) < iBands(NULL,TFOpt,BBPeriod,BBAbweichung,BBShift,PRICE_CLOSE,MODE_MAIN,2)){
            
            if(GegenrichtungSchliessen && OrdersTotal() > 0){
               OrdersSuchen(2);
            }
            
               LongOrder();
            
            }
          
                   // auf BB-MA-Cross prüfen "Letzte Kerze schließt oberhalb des MA und vorletzte Kerze schließt unterhalb des MA" 
         
         if(GetHA(TFOpt,3,1) < iBands(NULL,TFOpt,BBPeriod,BBAbweichung,BBShift,PRICE_CLOSE,MODE_MAIN,1) &&
            GetHA(TFOpt,3,2) > iBands(NULL,TFOpt,BBPeriod,BBAbweichung,BBShift,PRICE_CLOSE,MODE_MAIN,2)){

            if(GegenrichtungSchliessen && OrdersTotal() > 0){
               OrdersSuchen(1);
            }
            
               ShortOrder();
            
            }
         
       }
         
         
         // SL nachziehen
         TrailingAlls();
      if(TimeHour(TimeCurrent()) == HandelbisHH &&       
         TimeMinute(TimeCurrent()) < 2){
         
         OrdersSuchen(1);
         OrdersSuchen(2);
         
         }
     }
      
  }
//+------------------------------------------------------------------+
