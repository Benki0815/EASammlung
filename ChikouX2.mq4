//+------------------------------------------------------------------+
//|                                                     ChikouX2.mq4 |
//|                                                    Stephan Benik |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Stephan Benik"
#property link      ""
#property version   "1.01"
#property strict
//Idee:
//Indikation:
//Zwei nachlaufende Chikou Span (EMA 0) mit 26 und 38 Kerzen Nachlauf.
//
//Bestätigung:
//Eine Trendlinie (SMA 20)
//Eine schnelle Trendlinie (EMA 16)
//Eine langsame Trendlinie (EMA 26)
//
//Handelssignale:
//
//Kreuzt der 38er Chikou Span den 26er Chikou Span von unten nach oben erzeugt dies ein Long Signal
//Bestätigung: Preis liegt oberhalb der Trednlinie SMA20 und Schnelle Trendlinie EMA 16 kreuzt langsame EMA26 von unten nach oben
//
//
//



// Globale, änderbare Variablen
extern int Chikou_lang_Wert = 52; // Chikou lang
extern int Chikou_kurz_Wert = 13; // Chikou kurz
extern int EMA_lang_Wert    = 42; // langer EMA
extern int EMA_kurz_Wert    = 11; // kurzer EMA
extern int SMABasis_Wert    = 49; // Trendbasis-SMA
extern int SyncDurchlauf    = 6;     // Synchrolänge
extern int Handelsart       = 4;  // 1=Posi-Tausch 2=TSL 3=ATI 4=RSI
extern int Anzahl           = 1;  // Anzahl CFDs
extern double TrailingStop  = 4300;
extern double Stoploss      = 50; // SL in Punkten
extern double ATRTP         = 3.33; // ATR Takeprofit
extern double ATRSL         = 5.0; // ATR Stoploss
extern double ATRBESL       = 3.0; // ATR BE Stoploss
extern int    ATRPeriode    = 14; // Berechnungsgrundlage ATR
extern int    RSIPeriode    = 14; // RSI Periode
extern double RSITPL        = 70; // RSI Schwellwert Long
extern double RSITPS        = 30; // RSI Schwellwert Short
extern double RSIAW1        = 5;  // RSI Abknickwert
extern int Timeframe        = 0; // 0 = aktueller Chart
extern int BEStoploss       = 1; // 0 = deaktivert, 1 = RSISL-Abstand
bool Handelszeiten   = false;  // Nur zu bestimmten Zeiten handeln?
int TradeOpenHH      = 07;  // Uhrzeit TradeClose 0 = ohne Begrenzung
int TradeOpenMM   = 00;  // Uhrzeit TradeClose 0 = ohne Begrenzung
extern int TradeClosingHH   = 21;  // Uhrzeit TradeClose 0 = ohne Begrenzung
extern int TradeClosingMM   = 55;  // Uhrzeit TradeClose 0 = ohne Begrenzung

// Globale Variablen
double SMABasis;
double Chikou_kurz1,Chikou_lang1,Chikou_kurz2,Chikou_lang2,Chikou_kurz3,Chikou_lang3;
double EMA_kurz1,EMA_lang1,EMA_kurz2,EMA_lang2,EMA_kurz3,EMA_lang3;
string HandelsSignal = "";
datetime PeriodenStartZeit;
bool NeuePeriodeBegonnen;
double MATrend;
int ShortSyncDurchlauf = 0;
int LongSyncDurchlauf = 0;
bool ShortSignal = false;
bool LongSignal = false;
bool ShortOrderAktiv = false;
bool LongOrderAktiv = false;
double takeprofit = 0;
int Ticket;           // Order ticket
double Lot; 
double Price_Cls;
int MagicNumber = 102090;
double stopl;
string Text = "unbelegt";
int LOrder,SOrder;
int StoplossGesetzt = false;



// Globale Funktionen
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
         ShortOrderAktiv = false;
         LongOrderAktiv  = false;
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
  
int LongOrder(){
   if(Handelsart == 3){
   
      takeprofit = Ask+(iATR(NULL,0,ATRPeriode,0)*ATRTP);
      stopl = Ask - (iATR(NULL,0,ATRPeriode,0)*ATRSL); 
   } else {takeprofit = 0;
           stopl = Ask-Stoploss;
           }
   
   Comment("TP: ",takeprofit,"  SL: ",stopl," ATR: ",iATR(NULL,0,ATRPeriode,0));
  
   LOrder = OrderSend(Symbol(),OP_BUY,Anzahl,Ask,10,stopl,takeprofit,"EA ChikouX",MagicNumber,0,Green);
   if(BEStoploss == 1){
               TrailingStop = iATR(NULL,0,ATRPeriode,0)*ATRBESL*100;
               StoplossGesetzt = false;
            }
   return(0);
}

int ShortOrder(){
   if(Handelsart == 3){
      takeprofit = Bid - (iATR(NULL,0,ATRPeriode,0)*ATRTP);
      stopl = Bid + (iATR(NULL,0,ATRPeriode,0)*ATRSL);
   } else {takeprofit = 0;
           stopl = Bid+Stoploss;
           }

   Comment("TP: ",takeprofit,"  SL: ",stopl," ATR: ",iATR(NULL,0,ATRPeriode,0));
   SOrder = OrderSend(Symbol(),OP_SELL,Anzahl,Bid,10,stopl,takeprofit,"EA Trendkauf",MagicNumber,0,Red);
   if(BEStoploss == 1){
               TrailingStop = iATR(NULL,0,ATRPeriode,0)*ATRBESL*100;
               StoplossGesetzt = false;
            }   
   return(0);
}

void TrailOrder(int type)
{
   if(TrailingStop>0){
      if(OrderMagicNumber() == MagicNumber){
         if(type==OP_BUY){
            if(Bid-OrderOpenPrice()>Point*TrailingStop){ 
               if(OrderStopLoss() < Bid-Point*TrailingStop){ // Orig.: if(OrderStopLoss()) <<<<< Abfrage passt noch nicht!
                  if(OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green) == false){
                     Print("Trailing-Stoploss Order Modify konnte nicht durchgeführt werden: ", GetLastError());
                  }
               }
            }
         }
         if(type==OP_SELL){
            if((OrderOpenPrice()-Ask)>(Point*TrailingStop)){
               if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0)){
                  if(OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red) == false){
                     Print("Trailing-Stoploss Order Modify konnte nicht durchgeführt werden: ", GetLastError());
                  }
               }
            }
         }
      }
   }
}

int trailing(){
      int cnt,total;
      total = OrdersTotal();

      for(cnt=0;cnt<total;cnt++) {
         if(OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES)){
            if(OrderType()<=OP_SELL && OrderSymbol()==Symbol()){
               if(OrderType()==OP_BUY){ //<-- Long position is opened        
                  TrailOrder(OrderType()); return(0); //<-- Trailing the order
               }
               if(OrderType()==OP_SELL){ //<-- Go to short position
                  TrailOrder(OrderType()); return(0); //<-- Trailing the order
               }
               if(BEStoploss == 1){StoplossGesetzt = true;}
            }
         }
      } // END for
      return(0);
     } // END start()

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   PeriodenStartZeit = Time[0]; // Einmaliges Setzen des Zeitstempels
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
      PeriodenStartZeit = Time[0];
   } else { NeuePeriodeBegonnen = false; }
   
   if((NeuePeriodeBegonnen == true &&
       Handelszeiten == false) ||
      (NeuePeriodeBegonnen == true &&
       Handelszeiten == true       &&
       TimeHour(TimeCurrent()) >= TradeOpenHH &&
       TimeHour(TimeCurrent()) <= TradeClosingHH
      )
   
   ){
   //Handelssignale ermitteln
   Chikou_kurz1 = iClose(NULL,Timeframe,Chikou_lang_Wert - Chikou_kurz_Wert + 2);
   Chikou_lang1 = iClose(NULL,Timeframe,2);
   Chikou_kurz2 = iClose(NULL,Timeframe,Chikou_lang_Wert - Chikou_kurz_Wert + 1);
   Chikou_lang2 = iClose(NULL,Timeframe,0);
   Chikou_kurz3 = iClose(NULL,Timeframe,Chikou_lang_Wert - Chikou_kurz_Wert);
   Chikou_lang3 = iClose(NULL,Timeframe,0);
   
   if(ShortSignal == true){
      if(ShortSyncDurchlauf < SyncDurchlauf){ShortSyncDurchlauf++;} 
         else {ShortSyncDurchlauf = 0;
               ShortSignal = false;}
   }
   
   if(LongSignal == true){
      if(LongSyncDurchlauf < SyncDurchlauf){LongSyncDurchlauf++;} 
         else {LongSyncDurchlauf = 0;
               LongSignal = false;}
   }
   
   
   MATrend = iMA(NULL,Timeframe,SMABasis_Wert,0,MODE_SMA,PRICE_CLOSE,0);
   EMA_kurz1    = iMA(NULL,Timeframe,EMA_kurz_Wert,0,MODE_EMA,PRICE_CLOSE,2);
   EMA_lang1    = iMA(NULL,Timeframe,EMA_lang_Wert,0,MODE_EMA,PRICE_CLOSE,2);
   EMA_kurz2    = iMA(NULL,Timeframe,EMA_kurz_Wert,0,MODE_EMA,PRICE_CLOSE,1);
   EMA_lang2    = iMA(NULL,Timeframe,EMA_lang_Wert,0,MODE_EMA,PRICE_CLOSE,1);
   EMA_kurz3    = iMA(NULL,Timeframe,EMA_kurz_Wert,0,MODE_EMA,PRICE_CLOSE,0);
   EMA_lang3    = iMA(NULL,Timeframe,EMA_lang_Wert,0,MODE_EMA,PRICE_CLOSE,0);

    if(Chikou_lang1     < Chikou_kurz1 &&
       Chikou_lang2     > Chikou_kurz2 &&
       Chikou_lang3     > Chikou_kurz3 &&
       LongSignal     == false 
       )
       {
        LongSignal = true; 
       }
       
     if(LongSignal == true && 
        LongOrderAktiv == false) {
         if(iClose(NULL,Timeframe,0) > MATrend      &&
            EMA_kurz1        < EMA_lang1    &&
            EMA_kurz2        > EMA_lang2    &&
            EMA_kurz3        > EMA_lang3){
            
               Alert("LONG-SIGNAL: Schließe offene Orders");
               OffeneOrderSchliessen();
               LongOrder();
               LongOrderAktiv = true;
               LongSignal = false;
         }
          
    }
       
    if(Chikou_lang1     > Chikou_kurz1 &&
       Chikou_lang2     < Chikou_kurz2 &&
       Chikou_lang3     < Chikou_kurz3 &&
       ShortSignal     == false 
       )
       {
        ShortSignal = true; 
       }
       
     if(ShortSignal == true &&
        ShortOrderAktiv == false) {
         if(iClose(NULL,Timeframe,0) < MATrend      &&
            EMA_kurz1        > EMA_lang1    &&
            EMA_kurz2        < EMA_lang2    &&
            EMA_kurz3        < EMA_lang3){
            
               Alert("SHORT-SIGNAL: Schließe offene Orders");
               OffeneOrderSchliessen();
               ShortOrder();
               ShortOrderAktiv = true;
               ShortSignal = false;
         }
          
    }
   if(Handelsart == 2){ // TSL auf Break-Even
      trailing();
   } else {
            if(BEStoploss == 1 && StoplossGesetzt == false){
               trailing();
            }
   
     }
   if(Handelsart == 4 && OrdersTotal() > 0){  // TP auf RSI-Basis: Wenn Schwellwerte RSi überschritten und abgeknickt in Gegenrichtung -> Close
      if(OrderMagicNumber() == MagicNumber){
      int cnt,total;
      total = OrdersTotal();

      for(cnt=0;cnt<total;cnt++) {
         if(OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES))
            {
               if(OrderType()== OP_BUY && 
                  OrderSymbol()== Symbol() &&
                  iRSI(NULL,0,RSIPeriode,PRICE_CLOSE,1) > RSITPL &&
                  iRSI(NULL,0,RSIPeriode,PRICE_CLOSE,0) > RSITPL &&
                  (iRSI(NULL,0,RSIPeriode,PRICE_CLOSE,1)+RSIAW1) > RSITPL
                  ){ Alert("offene Long-Order schliessen. RSI: ",iRSI(NULL,0,RSIPeriode,PRICE_CLOSE,0));
                     OffeneOrderSchliessen();
               }
               if(OrderType()== OP_SELL &&
                  OrderSymbol()== Symbol() &&
                  iRSI(NULL,0,RSIPeriode,PRICE_CLOSE,1) < RSITPS &&
                  iRSI(NULL,0,RSIPeriode,PRICE_CLOSE,0) < RSITPS &&
                  (iRSI(NULL,0,RSIPeriode,PRICE_CLOSE,1)+RSIAW1) < RSITPS
                  ){Alert("offene SHORT-Order schliessen. RSI: ",iRSI(NULL,0,RSIPeriode,PRICE_CLOSE,0)); 
                    OffeneOrderSchliessen();
               }
            }
      }
      }
   }
   
   } //ENDE NeuePeriodeBegonnen
   
   if(TimeHour(TimeCurrent()) == TradeClosingHH && 
      TradeClosingHH > 0 &&
      TimeMinute(TimeCurrent()) == TradeClosingMM &&
      TradeClosingMM > 0){
         OffeneOrderSchliessen();
      }

      
  }
//+------------------------------------------------------------------+
