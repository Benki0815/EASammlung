//+------------------------------------------------------------------+
//|                                            Tagessystematik20.mq4 |
//|                                                    Stephan Benik |
//|                                nach einer Strategie von DuMaddin |
//|
//| Änderungsprotokoll nach Auslieferung der Beta 1.00:
//  1.01: Kommentarelöschen von INIT auf Tageswechsel verschoben, da sonst bei jedem Wechsel der Zeitperiode der Kommentar gelöscht wird
//        EMA-Crossing einen Tag nach hinten gesetzt - testhalber wieder zurück
//  1.02: Kommentarfunktion: Kommentare werden jetzt nicht überschrieben, sonder gelöscht und neu geschrieben
//  1.03: Kommentarfunktion: Kommentare bei Short: Fehler behoben (es wurde eine Long-Order gesucht, wir sind aber Short)
//  1.04: Rücksetzen auf M1 bei Tageswechsel um einen versehentlichen Wechsel auf einen höheren Chart zu korrigieren
//  1.05: Fehler bei Vola-Kickout behoben (?) ergänzende Angaben für Kickout-Berechnung ins Journal geschrieben
//        Vola Berechnungstag: Ist Markt des BasisSymbols noch geschlossen, ist Tageskerze vom Vortag noch aktuell, sonst 1 Kerze Versatz
//  
//+------------------------------------------------------------------+
#property copyright "Stephan Benik"
#property link      ""
#property version   "1.05"
#property description "Nach einer Strategie von DuMaddin"
#property strict

// globale, änderbare Variabeln
extern double VolaKickoutWert = 3.45; // Schwellwert VolaKickout (3.54)
extern double TPLong          = 5.6;  // TakeProfit Long in %    (3.15)
extern double TPShort         = 3.5;  // TakeProfit Short in %   (2.05)
extern double SLLong          = 0.4;  // StoppLoss Long in %     (1.04)
extern double SLShort         = 0.6;  // StoppLoss Short in %    (1.04)
extern bool   Dynamik         = true; // Anzahl CFDs nach Budget
extern int AnzahlCFD          = 1;    // Anzahl der CFDs (fest)
extern int MaximalAnzahlCFD   = 50;   // Max. Anz. CFD bei Dynamik
extern double RisikoWert      = 5;    // Risikowert (%) auf Gesamtbudget
extern string BasisSymbol     = ".DE30CashXE"; // Instrument zur Berechnung der Handelsrichtung 0 = aktueller Chart
extern int BasisPeriode       = 1440; // Periode für Handelsrichtung 0 = akt. Chart 1440=1D, 60=1H
extern int ATRPeriode         = 16;   // Periode für Tagesrange (16)
extern double ATRTPFaktor     = 1.55; // TP-Faktor Tagesrange (1.55)
extern double ATRSLFaktor     = 0.96; // SL-Faktor Tagesrange (0.96)
extern string ATRBasisSymbol  = "0";  // Instrument zur Berechnung des 16 Tage-Range-Schnitts 0 = aktueller Chart
extern int EMABasisWert       = 68;   // EMA-Basis für Handelsrichtung (68)
extern int EMAHRkurz          = 4;    // EMA für Handelsrichtung kurz (4)
extern int EMAHRlang          = 168;  // EMA für Handelsrichtung lang (168)
extern int KaufStunde         = 6;    // Stunde für Kauf (7)
extern int KaufMinute         = 57;   // Minute für Kauf (55)
extern int CloseStunde        = 20;   // Stunde für Close (21)
extern int CloseMinute        = 57;   // Minute für Close (55)
extern bool  TS20             = true; // Handel nach TS 2.0
// extern string Handelstage     = "TTTTT"; // T=Trade, F=Flat, MDMDF


// globale, nicht änderbare Variabeln
datetime PeriodenStartZeit;
bool NeuePeriodeBegonnen;
bool TradeAktiv = false;
bool VolaKickout = false;
string Bear[7] = {"F","S","L","L","L","S","F"}; // Handelsmatrix bearish orig.: "F","S","L","L","L","S","F"
string Bull[7] = {"F","L","S","S","L","S","F"}; // Handelsmatrix bullish orig.: "F","L","S","S","L","S","F" Mod. Donnerstag F
int MagicNumber = 197404;
double TagesSchwankung,stopl,takeprofit,Lot,Price_Cls,OpenPrice,StopLoss,TakeProfit;
int LOrder,SOrder,Ticket,StartTag,AnzahlLots,Versatz; 
string Text = "unbelegt";
string Kommentar1,Kommentar2;


// globale Funktionen
int PeriodenNullsetzen(){
    // Variablen zum Periodenbeginn auf Anfangswert
    TradeAktiv  = false;
    VolaKickout = false;
    return(0);
};

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

if(TS20){
   takeprofit = Ask + (iATR(ATRBasisSymbol,1440,ATRPeriode,0)*ATRTPFaktor);
   stopl      = Ask - (iATR(ATRBasisSymbol,1440,ATRPeriode,0)*ATRSLFaktor);
}  else {stopl      = Ask * (1 - (SLLong / 100));
         takeprofit = Ask * (1 + (TPLong / 100));
         }

if(Dynamik){ AnzahlLots = floor((AccountBalance() * RisikoWert / 100) / (Ask * SLLong / 100)); // Achtung an TS20 anpassen!
             if(AnzahlLots > MaximalAnzahlCFD){ AnzahlLots = MaximalAnzahlCFD;};
} else {AnzahlLots = AnzahlCFD;}
if(AnzahlLots <= 0){Alert("Kein Trade möglich. Anzahl Lots mit dem angegebenen Risiko < = 0.");
                    return(0);
}
   Alert("ACCOUNT-BALANCE: ",AccountBalance());
   Alert("ORDER LONG:",Ask," TP: ",DoubleToStr(takeprofit,2),"  SL: ",DoubleToStr(stopl,2)," Anzahl Lots: ",AnzahlLots);
   LOrder = OrderSend(Symbol(),OP_BUY,AnzahlLots,Ask,10,stopl,takeprofit,"Tagessystematik2.0",MagicNumber,0,Green);
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
   Kommentare_loeschen();
   Kommentar1 = StringConcatenate("Wir sind LONG mit ",AnzahlLots," Lot(s). Kaufpreis: ",(OpenPrice==0.00) ? "nicht ermittelbar" : OpenPrice);
   Kommentar2 = StringConcatenate("Stoploss: ",(StopLoss == 0.00) ? "nicht ermittelbar" : StopLoss," Takeprofit: ",(TakeProfit == 0.00) ? "nicht ermittelbar" : TakeProfit);
   Kommentare(Kommentar1,Kommentar2);
/*
   if(BEStoploss == 1){
               TrailingStop = iATR(NULL,0,ATRPeriode,0)*ATRBESL*100;
               StoplossGesetzt = false;
            }
*/
   return(0);
}

int ShortOrder(){

if(TS20){
   takeprofit = Bid - (iATR(ATRBasisSymbol,1440,ATRPeriode,0)*ATRTPFaktor);
   stopl      = Bid + (iATR(ATRBasisSymbol,1440,ATRPeriode,0)*ATRSLFaktor);
}  else {stopl      = Bid * (1 + (SLLong / 100));
         takeprofit = Bid * (1 - (TPLong / 100));
         }

if(Dynamik){ AnzahlLots = floor((AccountBalance() * RisikoWert / 100) / (Bid * SLShort /100));
             if(AnzahlLots > MaximalAnzahlCFD){ AnzahlLots = MaximalAnzahlCFD;};
} else {AnzahlLots = AnzahlCFD;}
if(AnzahlLots <= 0){Alert("Kein Trade möglich. Anzahl Lots mit dem angegebenen Risiko < = 0");
                    return(0);
}
   Alert("ORDER SHORT:",Bid," TP: ",DoubleToStr(takeprofit,2),"  SL: ",DoubleToStr(stopl,2));
   SOrder = OrderSend(Symbol(),OP_SELL,AnzahlLots,Bid,10,stopl,takeprofit,"Tagessystematik2.0",MagicNumber,0,Red);
   if(OrderSelect(SOrder, SELECT_BY_TICKET)){
      OpenPrice = DoubleToString(OrderOpenPrice(),2);
      StopLoss  = DoubleToString(OrderStopLoss(),2);
      TakeProfit= DoubleToString(OrderTakeProfit(),2);
      }  else
           {
            OpenPrice  = 0.00;
            StopLoss   = 0.00;
            TakeProfit = 0.00;
           }
   Kommentare_loeschen();           
   Kommentar1 = StringConcatenate("Wir sind SHORT mit ",AnzahlLots," Lot(s). Kaufpreis: ",(OpenPrice==0.00) ? "nicht ermittelbar" : OpenPrice);
   Kommentar2 = StringConcatenate("Stoploss: ",(StopLoss == 0.00) ? "nicht ermittelbar" : StopLoss," Takeprofit: ",(TakeProfit == 0.00) ? "nicht ermittelbar" : TakeProfit);
   Kommentare(Kommentar1,Kommentar2);
/*
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
   PeriodenStartZeit = Time[0]; // Einmaliges Setzen des Zeitstempels
   StartTag = DayOfYear();

   // Plausibilitätsprüfung
   if(RisikoWert > 99){
    Alert("Eingestelltes Risiko ist größer als das Budget. Programmabbruch. Bitte Risikowert verringern und EA neu starten.");
    int null = 0;
    int abbruch = 1/null;
   }
   if(KaufStunde > 23){
    Alert("Eingestellte Stunde für Kauf ist größer 23. Wie soll das gehen? Programmabbruch. Bitte richtigen Zeitwert eingeben und EA neu starten.");
    int null = 0;
    int abbruch = 1/null;
   }
   if(CloseStunde > 23){
    Alert("Eingestellte Stunde für Close ist größer 23. Wie soll das gehen? Programmabbruch. Bitte richtigen Zeitwert eingeben und EA neu starten.");
    int null = 0;
    int abbruch = 1/null;
   }
   if(KaufMinute > 59){
    Alert("Eingestellte Minute für Kauf ist größer 59. Wie soll das gehen? Programmabbruch. Bitte richtigen Zeitwert eingeben und EA neu starten.");
    int null = 0;
    int abbruch = 1/null;
   }
   if(CloseMinute > 59){
    Alert("Eingestellte Minute für Close ist größer 59. Wie soll das gehen? Programmabbruch. Bitte richtigen Zeitwert eingeben und EA neu starten.");
    int null = 0;
    int abbruch = 1/null;
   }
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
   // Neuer Tag?
    if(StartTag == DayOfYear()){
   // Handelssignal feststellen
      if(TradeAktiv == false && 
         VolaKickout == false ){
         // Zeitfenster für Kauf erreicht?
         if(KaufStunde == TimeHour(TimeCurrent()) && 
            KaufMinute == TimeMinute(TimeCurrent())){
            // Handelsrichtung feststellen
             // Kickout
             // Orig: TagesSchwankung = ((iHigh(BasisSymbol,BasisPeriode,1) - iLow(BasisSymbol,BasisPeriode,1)) / iOpen(BasisSymbol,BasisPeriode,1)) * 100;
             // Versatz ermitteln (Wird die Tageskerze vor Handelsstart abgefragt ist die aktuelle, die des Vortags!)
             Versatz = ( TimeDay(TimeCurrent()) * -1) + TimeDay(MarketInfo(BasisSymbol,MODE_TIME)) +1;
             Print("Berechneter Versatz: ",Versatz);
             // TagesSchwankung = ((iHigh(BasisSymbol,BasisPeriode,Versatz) - iLow(BasisSymbol,BasisPeriode,Versatz)) / iOpen(BasisSymbol,BasisPeriode,Versatz)) * 100;
             // TagesSchwankung = ((iHigh(BasisSymbol,BasisPeriode,1) - iLow(BasisSymbol,BasisPeriode,1)) / iOpen(BasisSymbol,BasisPeriode,1)) * 100;
             TagesSchwankung = 1;
             Alert("Vola Tagesschwankung für ",BasisSymbol," für ",iTime(BasisSymbol,BasisPeriode,1),": ",DoubleToStr(TagesSchwankung,2)," % MarketInfo-Zeit: ",MarketInfo(BasisSymbol,MODE_TIME));
               if(TagesSchwankung <= VolaKickoutWert){
                  
                  
          // <<<<<<>>>>>>>>>     EMA_kurz1    = iMA(NULL,Timeframe,EMA_kurz_Wert,0,MODE_EMA,PRICE_CLOSE,2);      
                 if(iMA(BasisSymbol,BasisPeriode,EMAHRkurz,0,MODE_EMA,PRICE_CLOSE,0) > iMA(BasisSymbol,BasisPeriode,EMAHRlang,1,MODE_EMA,PRICE_CLOSE,0) &&
                    iMA(BasisSymbol,BasisPeriode,EMAHRkurz,1,MODE_EMA,PRICE_CLOSE,0) < iMA(BasisSymbol,BasisPeriode,EMAHRlang,2,MODE_EMA,PRICE_CLOSE,0)
                 ){
                // EMA Crossing > LONG!
                   Alert("EMA Crossing! Order: LONG");
                   LongOrder();
                   TradeAktiv = true;
                 
                 } else {  if(iMA(BasisSymbol,BasisPeriode,EMAHRkurz,0,MODE_EMA,PRICE_CLOSE,0) < iMA(BasisSymbol,BasisPeriode,EMAHRlang,1,MODE_EMA,PRICE_CLOSE,0) &&
                              iMA(BasisSymbol,BasisPeriode,EMAHRkurz,1,MODE_EMA,PRICE_CLOSE,0) > iMA(BasisSymbol,BasisPeriode,EMAHRlang,2,MODE_EMA,PRICE_CLOSE,0)
                              ){
                             // EMA Crossing > SHORT
                                Alert("EMA Crossing! Order: SHORT");
                                ShortOrder();
                                TradeAktiv = true;
                                
                                // Handelstage deaktiviert. Ergebnisse waren deutlich schlechter....  &&
                                 //    StringSubstr(Handelstage,TimeDayOfWeek(TimeCurrent()),1) == "T")
                              
                              } else { if(iClose(BasisSymbol,BasisPeriode,1) > iMA(BasisSymbol,BasisPeriode,EMABasisWert,0,MODE_EMA,PRICE_CLOSE,1)){ // Close Vortag > EMA99 = Bull
                                           Alert("Bull-Signal: Close VT:",DoubleToStr(iClose(BasisSymbol,BasisPeriode,1),2)," EMA VT:",DoubleToStr(iMA(BasisSymbol,BasisPeriode,EMABasisWert,0,MODE_EMA,PRICE_CLOSE,1),2));
                                           if(Bull[TimeDayOfWeek(TimeCurrent())] == "L"){
                                             Alert("Order: LONG");
                                             LongOrder();
                                             TradeAktiv = true;
                                           }
                                           if(Bull[TimeDayOfWeek(TimeCurrent())] == "S"){
                                             Alert("Order: SHORT");
                                             ShortOrder();
                                             TradeAktiv = true;
                                           }
                                           if(Bull[TimeDayOfWeek(TimeCurrent())] == "F"){
                                             Alert("No Order: FLAT (No trading day)");
                                             TradeAktiv = true;
                                           }
                                        }
                                        if(iClose(BasisSymbol,BasisPeriode,1) < iMA(BasisSymbol,BasisPeriode,EMABasisWert,0,MODE_EMA,PRICE_CLOSE,1)){ // Close Vortag < EMA99 = Bear
                                           Alert("Bear-Signal: Close VT:",DoubleToStr(iClose(BasisSymbol,BasisPeriode,1),2)," EMA VT:",DoubleToStr(iMA(BasisSymbol,BasisPeriode,EMABasisWert,0,MODE_EMA,PRICE_CLOSE,1),2));
                                           if(Bear[TimeDayOfWeek(TimeCurrent())] == "L"){
                                             Alert("Order: LONG");
                                             LongOrder();
                                             TradeAktiv = true;
                                           }
                                           if(Bear[TimeDayOfWeek(TimeCurrent())] == "S"){
                                             Alert("Order: SHORT");
                                             ShortOrder();
                                             TradeAktiv = true;
                                           }
                                           if(Bear[TimeDayOfWeek(TimeCurrent())] == "F"){
                                             Alert("No Order: FLAT (No trading day)");
                                             TradeAktiv = true;
                                           }
                                          } 
                                        }
                                     }
                        }   else { VolaKickout = true;                    
                                   Alert("Vola-Kickout. !FLAT! Vola: ",DoubleToStr(TagesSchwankung,2)," % ");
                                   Kommentare("VOLA-KICKOUT!","Wir sind heute FLAT!");}

                           
            // Order
         
         } // EndIf Zeitfenster
      } //EndIf Handelssignal
     } // END Selber Tag?
       else {  PeriodenNullsetzen();          // -> Neuer Tag
               StartTag = DayOfYear();          // Neuen Tag setzen
               Alert("Tageswechsel auf ",TimeDay(TimeCurrent()),".",TimeMonth(TimeCurrent()),".",TimeYear(TimeCurrent()));
               ChartSetSymbolPeriod(0,NULL,1);
               Alert("Chart auf 1M gesetzt");
               // alte Kommentare aus Chart löschen
               Kommentare_loeschen();
       }
    } // EndIfPeriodeBegonnen
    
    // Zeitfenster für Close erreicht?         <<<<<<<<<<<<< funktioniert nicht!
         if(CloseStunde == TimeHour(TimeCurrent()) && 
            CloseMinute == TimeMinute(TimeCurrent()) &&
            OrdersTotal() > 0 ){
            Alert("Zeitlimit für Close erreicht. Order Close initiiert");
            OffeneOrderSchliessen();
            Kommentare("Order","am Zeitlimit geschlossen");
            }
  } //EndOnTick
//+------------------------------------------------------------------+

/*

Tagesabgrenzung muss erfolgen.

*/
