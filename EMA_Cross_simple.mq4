//+------------------------------------------------------------------+
//|                                             EMA_Cross_Simple.mq4 |
//|                                    Copyright 2016, Stephan Benik |
//|                                                                  |
//|  kreuzt der Preis NACH Kerzenschluss den gewählten Durchschnitt, |
//|  wird ein Kaufsignal ausgelöst. Dabei kann eine festgelegte      |
//|  Anzahl an Bestätigungskerzen nötig sein                         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Stephan Benik"
#property link      ""
#property version   "1.00"
#property strict
// globale, änderbare Variablen
extern double TPLong          = 5.6;  // TakeProfit Long in %    (3.15)
extern double TPShort         = 3.5;  // TakeProfit Short in %   (2.05)
extern double SLLong          = 0.4;  // StoppLoss Long in %     (1.04)
extern double SLShort         = 0.6;  // StoppLoss Short in %    (1.04)
extern bool   Dynamik         = true; // Anzahl CFDs nach Budget
extern int AnzahlCFD          = 1;    // Anzahl der CFDs (fest)
extern int MaximalAnzahlCFD   = 50;   // Max. Anz. CFD bei Dynamik
extern double RisikoWert      = 5;    // Risikowert (%) auf Gesamtbudget
extern string GDurchschnitt   = "E";  // K S E = Kijun, SMA, EMA 
extern int Kijun_Basiswert    = 26;   // Kijunbasiswert
extern int EMA_Basiswert      = 50;   // EMA-Basiswert
extern int SMA_Basiswert      = 50;   // SMA-Basiswert
extern int Anzahl_BestBar     = 1;    // Anzahl Bars f. Signalbestätigung


// globale, nicht änderbare Variabeln
datetime PeriodenStartZeit;
bool NeuePeriodeBegonnen;
bool trade = false;
int MagicNumber = 197414;
double stopl,takeprofit,Lot,Price_Cls,OpenPrice,StopLoss,TakeProfit;
int LOrder,SOrder,Ticket,AnzahlLots,x; 
string Text = "unbelegt";
string Kommentar1,Kommentar2;
double kijun,kijun_high,kijun_low,ema,sma;
double Preis[100];

// int    counted_bars=IndicatorCounted();
int i = 0;

// globale Funktionen
int Kommentare(string KommentarZeile1,
               string KommentarZeile2){
ObjectCreate("comment_zeile1",OBJ_LABEL,0,0,0);
   ObjectSet("comment_zeile1",OBJPROP_XDISTANCE,10);
   ObjectSet("comment_zeile1",OBJPROP_YDISTANCE,20);
   ObjectSetText("comment_zeile1",KommentarZeile1,11,"Arial",White);

   ObjectCreate("comment_zeile2",OBJ_LABEL,0,0,0);
   ObjectSet("comment_zeile2",OBJPROP_XDISTANCE,10);
   ObjectSet("comment_zeile2",OBJPROP_YDISTANCE,40);
   ObjectSetText("comment_zeile2",KommentarZeile2,11,"Arial",White);
   WindowRedraw();
   return(0);
}

int Kommentare_loeschen(){
   ObjectDelete("comment_zeile1");
   ObjectDelete("comment_zeile2");
   WindowRedraw();
   return(0);   
}

int LongOrder(){

stopl      = Ask * (1 - (SLLong / 100));
takeprofit = Ask * (1 + (TPLong / 100));


if(Dynamik){ AnzahlLots = floor((AccountBalance() * RisikoWert / 100) / (Ask * SLLong / 100));
             if(AnzahlLots > MaximalAnzahlCFD){ AnzahlLots = MaximalAnzahlCFD;};
} else {AnzahlLots = AnzahlCFD;}
if(AnzahlLots <= 0){Alert("Kein Trade möglich. Anzahl Lots mit dem angegebenen Risiko < = 0.");
                    return(0);
}
   Alert("ACCOUNT-BALANCE: ",AccountBalance());
   Alert("ORDER LONG:",Ask," TP: ",DoubleToStr(takeprofit,2),"  SL: ",DoubleToStr(stopl,2)," Anzahl Lots: ",AnzahlLots);
   LOrder = OrderSend(Symbol(),OP_BUY,AnzahlLots,Ask,10,stopl,takeprofit,"EMA Cross Simple",MagicNumber,0,Green);
   if(OrderSelect(LOrder, SELECT_BY_TICKET)){
      OpenPrice = DoubleToString(OrderOpenPrice(),2);
      StopLoss  = DoubleToString(OrderStopLoss(),2);
      TakeProfit= DoubleToString(OrderTakeProfit(),2);
      }  else
           {
            OpenPrice  = 0.00;
            StopLoss   = 0.00;
            TakeProfit = 0.00;
           }
/*   Kommentar1 = StringConcatenate("Wir sind LONG mit ",AnzahlLots," Lot(s). Kaufpreis: ",(OpenPrice==0.00) ? "nicht ermittelbar" : OpenPrice);
   Kommentar2 = StringConcatenate("Stoploss: ",(StopLoss == 0.00) ? "nicht ermittelbar" : StopLoss," Takeprofit: ",(TakeProfit == 0.00) ? "nicht ermittelbar" : TakeProfit);
   Kommentare(Kommentar1,Kommentar2);

   if(BEStoploss == 1){
               TrailingStop = iATR(NULL,0,ATRPeriode,0)*ATRBESL*100;
               StoplossGesetzt = false;
            }
*/
   return(0);
}

int ShortOrder(){

stopl      = Bid * (1 + (SLLong / 100));
takeprofit = Bid * (1 - (TPLong / 100));


if(Dynamik){ AnzahlLots = floor((AccountBalance() * RisikoWert / 100) / (Bid * SLShort /100));
             if(AnzahlLots > MaximalAnzahlCFD){ AnzahlLots = MaximalAnzahlCFD;};
} else {AnzahlLots = AnzahlCFD;}
if(AnzahlLots <= 0){Alert("Kein Trade möglich. Anzahl Lots mit dem angegebenen Risiko < = 0");
                    return(0);
}
   Alert("ORDER SHORT:",Bid," TP: ",DoubleToStr(takeprofit,2),"  SL: ",DoubleToStr(stopl,2));
   SOrder = OrderSend(Symbol(),OP_SELL,AnzahlLots,Bid,10,stopl,takeprofit,"EMA Cross Simple",MagicNumber,0,Red);
   if(OrderSelect(LOrder, SELECT_BY_TICKET)){
      OpenPrice = DoubleToString(OrderOpenPrice(),2);
      StopLoss  = DoubleToString(OrderStopLoss(),2);
      TakeProfit= DoubleToString(OrderTakeProfit(),2);
      }  else
           {
            OpenPrice  = 0.00;
            StopLoss   = 0.00;
            TakeProfit = 0.00;
           }
/*   Kommentar1 = StringConcatenate("Wir sind SHORT mit ",AnzahlLots," Lot(s). Kaufpreis: ",(OpenPrice==0.00) ? "nicht ermittelbar" : OpenPrice);
   Kommentar2 = StringConcatenate("Stoploss: ",(StopLoss == 0.00) ? "nicht ermittelbar" : StopLoss," Takeprofit: ",(TakeProfit == 0.00) ? "nicht ermittelbar" : TakeProfit);
   Kommentare(Kommentar1,Kommentar2);

   if(BEStoploss == 1){
               TrailingStop = iATR(NULL,0,ATRPeriode,0)*ATRBESL*100;
               StoplossGesetzt = false;
            }   
*/            
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
         if (OrderSymbol()!= Symb) continue;    // Symbol is not ours
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
         Alert("Keine offenen Orders für ",Symb," vorhanden");
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
      Alert("Versuche ",Text," ",Ticket," zu schließen. Warte auf Antwort...");
      bool Ans=OrderClose(Ticket,Lot,Price_Cls,2);// Order closing
      //-------------------------------------------------------------------------- 8 --
      if (Ans==true)                            // Got it! :)
        {
         Alert (Text," geschlossen ",Ticket);
         break;                                 // Exit closing cycle
        }
      //-------------------------------------------------------------------------- 9 --
      int Error=GetLastError();                 // Failed :(
      switch(Error)                             // Overcomable errors
        {
         case 135:
            { 
            Alert("The price has changed. Retrying..");
            RefreshRates();                     // Update data
            }
            continue;                           // At the next iteration
         case 136:
            {
            Alert("No prices. Waiting for a new tick..");
            while(RefreshRates()==false)        // To the new tick
               Sleep(1);                        // Cycle sleep
            }
            continue;                           // At the next iteration
         case 146:
            {
            Alert("Trading subsystem is busy. Retrying..");
            Sleep(500);                         // Simple solution
            RefreshRates();                     // Update data
            }
            continue;                           // At the next iteration
        }
      switch(Error)                             // Critical errors
        {
         case 2 : {Alert("Common error.");}
            break;                              // Exit 'switch'
         case 5 : {Alert("Old version of the client terminal.");}
            break;                              // Exit 'switch'
         case 64: {Alert("Account is blocked.");}
            break;                              // Exit 'switch'
         case 133:{Alert("Trading is prohibited");}
            break;                              // Exit 'switch'
         default: {Alert("Occurred error ",Error);}//Other alternatives   
        }
      break;                                    // Exit closing cycle
     }
   return(0);                                      // Exit OffeneOrderSchliessen()
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   PeriodenStartZeit = Time[0]; // Einmaliges Setzen des Zeitstempels
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
   
            // Kijun Handelssignal prüfen
            if(GDurchschnitt == "K" && trade == false){
               i=0;
               kijun_high = 0;
               kijun_low  = 999999999;
               while(i  <Kijun_Basiswert){
                  if(High[i] > kijun_high){
                   kijun_high = High[i];
                  }
                  if(Low[i] < kijun_low){
                   kijun_low = Low[i];
                  }
                  i++;
               }
                  kijun = (kijun_high+kijun_low)/2;
               // Prüfung, ob Preis Kijun von unten nach oben gekreuzt hat...
                  if(iClose(NULL,0,Anzahl_BestBar+2) < kijun &&
                     iClose(NULL,0,1) > kijun){
                        trade = true;
                        // Bestätigungsdurchläufe
                        for(x = 1; x <= Anzahl_BestBar+1; x++){
                           if(iClose(NULL,0,x) < kijun){trade = false;} // Wenn eine der Best.Bars unter dem Kijun liegt, kein Trade
                     
                     }
                  
                     if(trade == true){
                     OffeneOrderSchliessen();
                     LongOrder();
                     trade = false;
                     }
                        
                  }
               // Prüfung, ob Preis Kijun von oben nach unten gekreuzt hat...
                  if(iClose(NULL,0,Anzahl_BestBar+2) > kijun &&
                     iClose(NULL,0,1) < kijun){
                        trade = true;
                        // Bestätigungsdurchläufe
                        for(x = 1; x <= Anzahl_BestBar+1; x++){
                           if(iClose(NULL,0,x) > kijun){trade = false;} // Wenn eine der Best.Bars über dem Kijun liegt, kein Trade
                     
                     }
                  
                     if(trade == true){
                     OffeneOrderSchliessen();
                     ShortOrder();
                     trade = false;
                     }
                        
                  }
                  
                  
            }
      
      
      
      
      // EMA Handelssignal prüfen
      if(GDurchschnitt == "E"){
      
      // Prüfung, ob Preis EMA von unten nach oben gekreuzt hat...
                  if(iClose(NULL,0,Anzahl_BestBar+2) < iMA(NULL,0,EMA_Basiswert,0,MODE_EMA,PRICE_CLOSE,0) &&
                     iClose(NULL,0,1) > iMA(NULL,0,EMA_Basiswert,0,MODE_EMA,PRICE_CLOSE,0)){
                        trade = true;
                        // Bestätigungsdurchläufe
                        for(x = 1; x <= Anzahl_BestBar+1; x++){
                           if(iClose(NULL,0,x) < iMA(NULL,0,EMA_Basiswert,0,MODE_EMA,PRICE_CLOSE,0)){trade = false;} // Wenn eine der Best.Bars unter dem Kijun liegt, kein Trade
                     
                     }
                  
                     if(trade == true){
                     OffeneOrderSchliessen();
                     LongOrder();
                     trade = false;
                     }
                        
                  }
               // Prüfung, ob Preis Kijun von oben nach unten gekreuzt hat...
                  if(iClose(NULL,0,Anzahl_BestBar+2) > iMA(NULL,0,EMA_Basiswert,0,MODE_EMA,PRICE_CLOSE,0) &&
                     iClose(NULL,0,1) < iMA(NULL,0,EMA_Basiswert,0,MODE_EMA,PRICE_CLOSE,0)){
                        trade = true;
                        // Bestätigungsdurchläufe
                        for(x = 1; x <= Anzahl_BestBar+1; x++){
                           if(iClose(NULL,0,x) > iMA(NULL,0,EMA_Basiswert,0,MODE_EMA,PRICE_CLOSE,0)){trade = false;} // Wenn eine der Best.Bars über dem Kijun liegt, kein Trade
                     
                     }
                  
                     if(trade == true){
                     OffeneOrderSchliessen();
                     ShortOrder();
                     trade = false;
                     }
                        
                  }
      
      
      
      }
      
      
      // SMA Handelssignal prüfen
      if(GDurchschnitt == "S"){
      
            // Prüfung, ob Preis SMA von unten nach oben gekreuzt hat...
                  if(iClose(NULL,0,Anzahl_BestBar+2) < iMA(NULL,0,SMA_Basiswert,0,MODE_SMA,PRICE_CLOSE,0) &&
                     iClose(NULL,0,1) > iMA(NULL,0,SMA_Basiswert,0,MODE_SMA,PRICE_CLOSE,0)){
                        trade = true;
                        // Bestätigungsdurchläufe
                        for(x = 1; x <= Anzahl_BestBar+1; x++){
                           if(iClose(NULL,0,x) < iMA(NULL,0,SMA_Basiswert,0,MODE_SMA,PRICE_CLOSE,0)){trade = false;} // Wenn eine der Best.Bars unter dem Kijun liegt, kein Trade
                     
                     }
                  
                     if(trade == true){
                     OffeneOrderSchliessen();
                     LongOrder();
                     trade = false;
                     }
                        
                  }
               // Prüfung, ob Preis Kijun von oben nach unten gekreuzt hat...
                  if(iClose(NULL,0,Anzahl_BestBar+2) > iMA(NULL,0,SMA_Basiswert,0,MODE_SMA,PRICE_CLOSE,0) &&
                     iClose(NULL,0,1) < iMA(NULL,0,SMA_Basiswert,0,MODE_SMA,PRICE_CLOSE,0)){
                        trade = true;
                        // Bestätigungsdurchläufe
                        for(x = 1; x <= Anzahl_BestBar+1; x++){
                           if(iClose(NULL,0,x) > iMA(NULL,0,SMA_Basiswert,0,MODE_SMA,PRICE_CLOSE,0)){trade = false;} // Wenn eine der Best.Bars über dem Kijun liegt, kein Trade
                     
                     }
                  
                     if(trade == true){
                     OffeneOrderSchliessen();
                     ShortOrder();
                     trade = false;
                     }
                        
                  }
      
      
      }
   }
   
  }
//+------------------------------------------------------------------+
