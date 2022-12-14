//+------------------------------------------------------------------+
//|                                                     StocHart.mq4 |
//|                                    Copyright 2016, Stephan Benik |
//|                                                                  |
//|  Trendfolgesystem. Gekauft wird bei Umkehr/Crossing der Werte    |
//|  unter 20%(variabel), verkauft bei Umkehr/Crossing über 80% (v.) |
//|  Handelszeiten variabel. TP bei Signalumkehr, SL nach ATR + x%   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Stephan Benik"
#property link      ""
#property version   "1.00"
#property strict
// globale, änderbare Variablen
// extern double TPLong          = 5.6;  // TakeProfit Long in %    (3.15) ausschalten
// extern double TPShort         = 3.5;  // TakeProfit Short in %   (2.05) ausschalten
extern double SLLong          = 1.0;  // SL Buffer Long in %     (1.04)
extern double SLShort         = 1.0;  // SL Buffer Short in %    (1.04)
extern bool   Dynamik         = false; // Anzahl CFDs nach Budget
extern int AnzahlCFD       = 1;    // Anzahl der CFDs (fest)
extern int MaximalAnzahlCFD   = 50;   // Max. Anz. CFD bei Dynamik
extern double RisikoWert      = 5;    // Risikowert (%) auf Gesamtbudget
extern int HandelvonHH        = 3;    // Handel HH ab
extern int HandelvonMM        = 0;    // Handel MM ab
extern int HandelbisHH        = 21;    // Handel HH bis
extern int HandelbisMM        = 59;    // Handel MM bis
extern int KPeriod            = 5;    // %K Line (5)
extern int DPeriod            = 3;    // %D Line (3)
extern int Slowing            = 3;    // Glättung (3)
extern string StochModeMA     = "MODE_SMA"; // MA Mode for Stochastic
extern int ObereStochGrenze   = 80;   // Obere Grenze überkauft
extern int UntereStochGrenze  = 20;   // Obere Grenze überverkauft
extern int Toleranz           = 1;    // Toleranzwert Crossing in %
extern int ATRPeriode         = 12;   // ATR Basis Periode





// globale, nicht änderbare Variabeln
datetime PeriodenStartZeit;
bool NeuePeriodeBegonnen;
bool LTrade = false;
bool STrade = false;
int MagicNumber = 197416;
double stopl,takeprofit,Lot,Price_Cls,OpenPrice,StopLoss,TakeProfit; // 
int LOrder,SOrder,Ticket,AnzahlLots,x; 
string Text = "unbelegt";
string Kommentar1,Kommentar2;
string EAName = "STocChart";


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

// stopl      = Ask - (iATR(NULL,0,ATRPeriode,0) * (1 + (SLLong / 100)));
stopl      = Ask * (1 - (SLShort / 100)); 
takeprofit = 0;


if(Dynamik){ AnzahlLots = floor((AccountBalance() * RisikoWert / 100) / (Ask * SLLong / 100));
             if(AnzahlLots > MaximalAnzahlCFD){ AnzahlLots = MaximalAnzahlCFD;};
} else {AnzahlLots = AnzahlCFD;}
if(AnzahlLots < 0){Alert("Kein Trade möglich. Anzahl Lots mit dem angegebenen Risiko < = 0.");
                    return(0);
}

   Alert("ACCOUNT-BALANCE: ",AccountBalance());
   Alert("ORDER LONG:",Ask," TP: Gegensignal  SL: ",DoubleToStr(stopl,2)," Anzahl Lots: ",AnzahlLots);
   LOrder = OrderSend(Symbol(),OP_BUY,AnzahlLots,Ask,10,stopl,takeprofit,EAName,MagicNumber,0,Green);
/*   if(OrderSelect(LOrder, SELECT_BY_TICKET)){
      OpenPrice = DoubleToString(OrderOpenPrice(),2);
      StopLoss  = DoubleToString(OrderStopLoss(),2);
      TakeProfit= DoubleToString(OrderTakeProfit(),2);
      }  else
           {
            OpenPrice  = 0.00;
            StopLoss   = 0.00;
            TakeProfit = 0.00;
           }
   Kommentar1 = StringConcatenate("Wir sind LONG mit ",AnzahlLots," Lot(s). Kaufpreis: ",(OpenPrice==0.00) ? "nicht ermittelbar" : OpenPrice);
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

// stopl      = Bid + (iATR(NULL,0,ATRPeriode,0) * (1 + (SLShort / 100)));
stopl      = Bid * (1 + (SLShort / 100));
takeprofit = 0;


if(Dynamik){ AnzahlLots = floor((AccountBalance() * RisikoWert / 100) / (Bid * SLShort /100));
             if(AnzahlLots > MaximalAnzahlCFD){ AnzahlLots = MaximalAnzahlCFD;};
} else {AnzahlLots = AnzahlCFD;}
if(AnzahlLots <= 0){Alert("Kein Trade möglich. Anzahl Lots mit dem angegebenen Risiko < = 0");
                    return(0);
}
   Alert("ORDER SHORT:",Bid," TP: Gegensignal  SL: ",DoubleToStr(stopl,2));
   SOrder = OrderSend(Symbol(),OP_SELL,AnzahlLots,Bid,10,stopl,takeprofit,EAName,MagicNumber,0,Red);
/*   if(OrderSelect(LOrder, SELECT_BY_TICKET)){
      OpenPrice = DoubleToString(OrderOpenPrice(),2);
      StopLoss  = DoubleToString(OrderStopLoss(),2);
      TakeProfit= DoubleToString(OrderTakeProfit(),2);
      }  else
           {
            OpenPrice  = 0.00;
            StopLoss   = 0.00;
            TakeProfit = 0.00;
           }
   Kommentar1 = StringConcatenate("Wir sind SHORT mit ",AnzahlLots," Lot(s). Kaufpreis: ",(OpenPrice==0.00) ? "nicht ermittelbar" : OpenPrice);
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
   
       // Handelzeiten prüfen
          if(TimeHour(TimeCurrent()) >= HandelvonHH &&
             TimeHour(TimeCurrent()) <= HandelbisMM &&
             TimeMinute(TimeCurrent()) >= HandelvonMM &&
             TimeMinute(TimeCurrent()) <= HandelbisMM){
             
             // Offene Order prüfen
             if(OrdersTotal() < 1){
                LTrade = false;
                STrade = false;             
             }
             Print("Offene Orders (OrdersTotal): ",OrdersTotal());
             
         
             // Handelssignal prüfen
             if(iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_MAIN,1) < UntereStochGrenze){ // &&
         //       LTrade == false){
                Print("MODE_MAIN unter unterer Grenze (",UntereStochGrenze,"): ",DoubleToString(iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_MAIN,0)));
                  if( (iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_MAIN,1)*(1+(Toleranz/100))) > iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_SIGNAL,1) &&
                      (iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_MAIN,2)*(1-(Toleranz/100))) < iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_SIGNAL,2)
                    ){
                    Print("MODE_MAIN kreuzt MODE_SIGNAL von unten nach oben");
                      // ShortTrade offen? Ja > schließen
                         if(STrade){
                           while(OrdersTotal() > 0) {OffeneOrderSchliessen();}
                           STrade = false;
                         }
                    Print("Ggf. offene Order schließen");
                      // Long Trade eröffnen
                         LongOrder();
                    Print("LongOrder ausgeführt");
                         LTrade = true;
                    Print("LTrade = true gesetzt");
                  } else{Print("Untere Grenze zwar unterschritten, aber MODE_MAIN 1 (",DoubleToString(iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_MAIN,1)),
                                ") kreuzt MODE_SIGNAL 1 (",DoubleToString(iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_SIGNAL,1)),") nicht. MODE_MAIN 2 (",iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_MAIN,2),") MODE_SIGNAL 2: ",iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_SIGNAL,2),")");}
             }
             
             if(iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_MAIN,1) > ObereStochGrenze){ // &&
         //       STrade == false){
             
                  if((iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_MAIN,1)*(1+(Toleranz/100))) < iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_SIGNAL,1) &&
                     (iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_MAIN,2)*(1-(Toleranz/100))) > iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_SIGNAL,2)
                      ){
                    Print("MODE_MAIN kreuzt MODE_SIGNAL von oben nach unten");
                      // LongTrade offen? Ja > schließen
                      if(LTrade){
                        while(OrdersTotal() > 0) {OffeneOrderSchliessen();}
                        LTrade = false;
                      }
                    Print("Ggf. offene Order schließen");
                      // Long Trade eröffnen
                      ShortOrder();
                    Print("ShortOrder ausgeführt");
                      STrade = true;
                    Print("STrade = true gesetzt");
                  } else{Print("Obere Grenze zwar unterschritten, aber MODE_MAIN 1 (",DoubleToString(iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_MAIN,1)),
                                ") kreuzt MODE_SIGNAL 1 (",DoubleToString(iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_SIGNAL,1)),") nicht. MODE_MAIN 2: (",DoubleToString(iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_MAIN,2)),") MODE_SIGNAL 2: ",DoubleToString(iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_SIGNAL,2)),")");}
             }             
   }
   
   }
  }
//+------------------------------------------------------------------+
