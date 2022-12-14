//+------------------------------------------------------------------+
//|                                                         HAST.mq4 |
//|                                    Copyright 2016, Stephan Benik |
//|                                                                  |
//|        Heiken Ashi Supertrend - Trendfolge - Trading - System    |
//|  Schaltet der Supertrend von Short auf Long und ist die Heiken   |
//|  Ashi-Kerze grün > Short beenden, Long Trade beginnen. Und umgek.|
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Stephan Benik"
#property link      ""
#property version   "1.00"
#property strict
// globale, änderbare Variablen
extern double TPLong          = 0;  // TakeProfit Long in Punkten
extern double TPShort         = 0;  // TakeProfit Short in Punkten
extern double SLLong          = 0.2;  // SL Buffer Long in %     (1.04)
extern double SLShort         = 0.2;  // SL Buffer Short in %    (1.04)
extern bool   Dynamik         = false; // Anzahl CFDs nach Budget
extern double AnzahlCFD       = 0.05;    // Anzahl der CFDs (fest)
extern int MaximalAnzahlCFD   = 50;   // Max. Anz. CFD bei Dynamik
extern double RisikoWert      = 5;    // Risikowert (%) auf Gesamtbudget
extern double TrailingSL      = 100;  // SL in Pips
extern int HandelsPausevonHH  = 22;    // Handelspause HH ab
// extern int HandelsPausevonMM  = 00;    // Handelspause MM ab
extern int HandelsPausebisHH  = 5;    // Handelspause HH bis
// extern int HandelsPausebisMM  = 0;    // Handelspause MM bis
extern int ADXcrossesPeriod   = 24;   // ADX-Periode
// extern int HATimeFrame        = 5;    // Heiken Ashi TimeFrame
extern bool STBestaetigung    = true;
extern int STPeriode          = 50;    // ST Periode
extern int STFaktor           = 7;    // ST Faktor
extern int SLBE               = 5;    // SL + Pips = BE | 0 = AUS
extern int SLBESW             = 20;   // Schwellwert BE setzen
extern int MagicNumber        = 197444; // Magic Number
extern string EAName          = "ADX_Cross_SIGNAL"; // EA-Name für Kommentar
// extern int ATRPeriode         = 8;    // ATR Periode
extern int bars               = 1;    // StartKerze zurückrechnen
extern double ADX9TPSchwell   = 57;   // ADX(9) Schwellwert (0=AUS)
extern bool Gegensignal       = false; // Gegensignal beendet Trade
extern bool OrdersOvernight   = false; // Orders über Nacht halten
extern int ADXMainEntfernung  = 5;    // Wie weit darf der ADXMain von DI+- entfernt sein (0=AUS)

// globale, nicht änderbare Variabeln
datetime PeriodenStartZeit;
bool NeuePeriodeBegonnen;
// bool LTrade = false;
// bool STrade = false;
double stopl,takeprofit,Lot,Price_Cls,OpenPrice,StopLoss,TakeProfit; // 
int LOrder,SOrder,Ticket,x,STShift; 
double AnzahlLots;
string Text = "unbelegt";
double UpperLevel = 100000;
double LowerLevel = 0.0001;
double UpperLevelNew;
double LowerLevelNew;
bool   TrendWechsel = false;
string SuperTrend = "UP";
double b4plusdi, b4minusdi, nowplusdi, nowminusdi;
string Trade;


// globale Funktionen

int ST(int STShift){
  TrendWechsel = false;
  UpperLevelNew = (iHigh(NULL,1,STShift) + iLow(NULL,1,STShift))/2+(STFaktor*iATR(NULL,1,STPeriode,STShift));
  LowerLevelNew = (iHigh(NULL,1,STShift) + iLow(NULL,1,STShift))/2-(STFaktor*iATR(NULL,1,STPeriode,STShift));
  // Trendbestimmung
  if(SuperTrend == "DOWN" && iClose(NULL,0,STShift) > UpperLevel){
      TrendWechsel = true;
      SuperTrend = "UP";
      LowerLevel = LowerLevelNew;
      return(TrendWechsel);
  } else { if(SuperTrend == "DOWN" && UpperLevelNew < UpperLevel){
               UpperLevel = UpperLevelNew;
           }
         }
  if(SuperTrend == "UP" && iClose(NULL,0,STShift) < LowerLevel){
      TrendWechsel = true;
      SuperTrend = "DOWN";
      UpperLevel = UpperLevelNew;
      return(TrendWechsel);
  } else { if(SuperTrend == "UP" && LowerLevelNew > LowerLevel){
               LowerLevel = LowerLevelNew;
           }
         }
  return(false);
}

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

int LongOrder(){

// stopl      = Ask - (iATR(NULL,0,ATRPeriode,0) * (1 + (SLLong / 100)));
stopl      = Ask * (1 - (SLShort / 100)); 
takeprofit = (TPLong == 0)? 0 : (Ask + TPLong);

if(Trade == "SHORT" && Gegensignal == true){OrdersSuchen(2);}

if(Dynamik){ AnzahlLots = floor((AccountBalance() * RisikoWert / 100) / (Ask * SLLong / 100));
             if(AnzahlLots > MaximalAnzahlCFD){ AnzahlLots = MaximalAnzahlCFD;};
} else {AnzahlLots = AnzahlCFD;}
if(AnzahlLots < 0){Alert("Kein Trade möglich. Anzahl Lots mit dem angegebenen Risiko < = 0.");
                    return(0);
}

   // Print("ACCOUNT-BALANCE: ",AccountBalance());
   // Alert("ORDER LONG:",Ask," TP: Gegensignal  SL: ",DoubleToStr(stopl,2),"oder Gegensignal. Anzahl Lots: ",AnzahlLots);
   LOrder = OrderSend(Symbol(),OP_BUY,AnzahlLots,Ask,10,stopl,takeprofit,EAName,MagicNumber,0,Green);
   if(LOrder != -1){
      Trade = "LONG";
      PlaySound("bulup.wav");
   } else {Print("Order-Fehler: ",GetLastError());}

   return(0);
}

int ShortOrder(){

// stopl      = Bid + (iATR(NULL,0,ATRPeriode,0) * (1 + (SLShort / 100)));
stopl      = Bid * (1 + (SLShort / 100));
takeprofit = (TPShort == 0) ? 0 : (Bid - TPShort);

if(Trade == "LONG" && Gegensignal == true){OrdersSuchen(1);}

if(Dynamik){ AnzahlLots = floor((AccountBalance() * RisikoWert / 100) / (Bid * SLShort /100));
             if(AnzahlLots > MaximalAnzahlCFD){ AnzahlLots = MaximalAnzahlCFD;};
} else {AnzahlLots = AnzahlCFD;}
if(AnzahlLots <= 0){Alert("Kein Trade möglich. Anzahl Lots mit dem angegebenen Risiko < = 0");
                    return(0);
}
  //  Alert("ORDER SHORT:",Bid," TP: Gegensignal  SL: ",DoubleToStr(stopl,2)," oder Gegensignal");
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

void TrailingAlls(int trail)
  {
   if(trail==0)
      return;
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
            stopcrnt=OrderStopLoss();
            stopcal=Bid-(trail*Point);
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
            stopcal=Ask+(trail*Point);
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
   if(SLBE == 0) return;
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
   
   Print("Hole Initial-Supertrend...");
   
   for(int zaehler = 300; zaehler > 0 ; zaehler--){
      ST(zaehler);
   }
   
   Print("Initial-Supertrend ist ",SuperTrend);
   
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

  
         ST(1);
         Kommentare_loeschen();
         Kommentare(StringConcatenate("SuperTrend ist ",SuperTrend),DoubleToStr(UpperLevel),DoubleToStr(LowerLevel),NULL);
         
   
       // Handelzeiten prüfen
          if(TimeHour(TimeCurrent()) > HandelsPausebisHH &&
             TimeHour(TimeCurrent()) < HandelsPausevonHH ){
          
          
        // TrailingAlls(TrailingSL);
        
        b4plusdi =   iADX(NULL, 0, ADXcrossesPeriod, PRICE_CLOSE, MODE_PLUSDI, bars + 1);
        nowplusdi =  iADX(NULL, 0, ADXcrossesPeriod, PRICE_CLOSE, MODE_PLUSDI, bars);
        b4minusdi =  iADX(NULL, 0, ADXcrossesPeriod, PRICE_CLOSE, MODE_MINUSDI, bars + 1);
        nowminusdi = iADX(NULL, 0, ADXcrossesPeriod, PRICE_CLOSE, MODE_MINUSDI, bars);  
        //----
        // Kommentare_loeschen();
        // Kommentare(DoubleToString(b4plusdi,4),DoubleToStr(b4minusdi,4),DoubleToStr(nowplusdi,4),DoubleToStr(nowminusdi,4));       
        
        if ( b4plusdi > b4minusdi && nowplusdi < nowminusdi ){
             Print("DI+ kreuzt von oben nach unten. Prüfe Bedingungen...");
             if(ADXMainEntfernung == 0){
                if(STBestaetigung){
                   if(SuperTrend == "DOWN"){
                     Print("SuperTrend ist DOWN. Short-Order ausführen.");
                     PlaySound("bulup.wav");
                     Print("SHORT kaufen");
                   } else {Print("Keine Order. SuperTrend ist UP");}
                
                } else { PlaySound("bulup.wav");
                         Print("SHORT kaufen");}
                        
             } else { if(STBestaetigung){
                         if(SuperTrend == "DOWN"){
                           Print("SuperTrend ist DOWN. ADX-Main-Entfernung prüfen...");
                           if(  iADX(NULL, 0, ADXcrossesPeriod, PRICE_CLOSE, MODE_MAIN, bars) < (nowplusdi + ADXMainEntfernung) &&
                                iADX(NULL, 0, ADXcrossesPeriod, PRICE_CLOSE, MODE_MAIN, bars) > (nowplusdi - ADXMainEntfernung)){
                                Print("ADX-Main ist innerhalb der Toleranz zu DI+ +- ",ADXMainEntfernung," > SHORT Trade");
                                PlaySound("bulup.wav");
                                Print("SHORT kaufen");
                           }    else {Print("Keine Order. ADX-Main ist außerhalb Toleranz");}
                           
                         } else {Print("Keine Order. SuperTrend ist UP");}
                      } else { PlaySound("bulup.wav");
                               Print("SHORT kaufen");}
                     }
            }
            
        if ( b4plusdi < b4minusdi && nowplusdi > nowminusdi ){
             Print("DI+ kreuzt von unten nach oben. Prüfe Bedingungen...");
             if(ADXMainEntfernung == 0){
                if(STBestaetigung){
                   if(SuperTrend == "UP"){
                     Print("SuperTrend ist UP. Long-Order ausführen.");
                     PlaySound("bulup.wav");
                     Print("LONG kaufen");
                   } else {Print("Keine Order. SuperTrend ist DOWN");}
                
                } else { PlaySound("bulup.wav");
                         Print("LONG kaufen");}
                        
             } else { if(STBestaetigung){
                         if(SuperTrend == "UP"){
                           Print("SuperTrend ist UP. ADX-Main-Entfernung prüfen...");
                           if(  iADX(NULL, 0, ADXcrossesPeriod, PRICE_CLOSE, MODE_MAIN, bars) < (nowplusdi + ADXMainEntfernung) &&
                                iADX(NULL, 0, ADXcrossesPeriod, PRICE_CLOSE, MODE_MAIN, bars) > (nowplusdi - ADXMainEntfernung)){
                                Print("ADX-Main ist innerhalb der Toleranz zu DI+ +- ",ADXMainEntfernung," > LONG Trade");
                                PlaySound("bulup.wav");
                                Print("LONG kaufen");
                           }    else {Print("Keine Order. ADX-Main ist außerhalb Toleranz");}
                           
                         } else {Print("Keine Order. SuperTrend ist DOWN");}
                      } else { PlaySound("bulup.wav");
                                Print("LONG kaufen");} 
                     }
            }


         } // Handelszeiten
         
         // Order bei abfallendem ADX(9) schließen
         if(ADX9TPSchwell != 0 && OrdersTotal() > 0 &&
            ( iADX(NULL,0,9,PRICE_CLOSE,MODE_MAIN,1) > ADX9TPSchwell ||
              iADX(NULL,0,9,PRICE_CLOSE,MODE_MAIN,2) > ADX9TPSchwell   )){
            if(iADX(NULL,0,9,PRICE_CLOSE,MODE_MAIN,1) < iADX(NULL,0,9,PRICE_CLOSE,MODE_MAIN,2)){
            Print("ADX(9) war oder ist über ",ADX9TPSchwell," und fällt ab. Order schließen");
               if(iADX(NULL, 0, ADXcrossesPeriod, PRICE_CLOSE, MODE_PLUSDI, bars) > iADX(NULL, 0, ADXcrossesPeriod, PRICE_CLOSE, MODE_MINUSDI, bars)){ // Long-Anstieg beendet
                  PlaySound("bulup.wav");
                  Print("Trade beenden!");
               } else { PlaySound("bulup.wav");
                        Print("Trade beenden!");}
            
            }
         
         }
        // Orders zu Handelspausenbeginn schließen
        if(OrdersOvernight == false && 
           TimeHour(TimeCurrent()) == HandelsPausevonHH &&
           TimeMinute(TimeCurrent()) == 0){
            Print("Kein Overnight-Handel. Orders schließen");
            OrdersSuchen(1);
            OrdersSuchen(2);
        
        }
        
        // SL auf BE setzen
       // if(SLBE > 0){SLBEsetzen();}
     }
      
  }
//+------------------------------------------------------------------+
