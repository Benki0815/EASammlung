//+------------------------------------------------------------------+
//|                                              MACD_HeikenAshi.mq4 |
//|                                    Copyright 2016, Stephan Benik |
//|                                                                  |
//|                           Heiken Ashi MACD - Trading - System    |
//|  Wechselt der MACD von Minus auf Plus, verkaufe Short, gehe Long |
//|  und umgekehrt                                                   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Stephan Benik"
#property link      ""
#property version   "1.00"
#property strict
// globale, änderbare Variablen
// extern double TPLong          = 5.6;  // TakeProfit Long in %    (3.15) ausschalten
// extern double TPShort         = 3.5;  // TakeProfit Short in %   (2.05) ausschalten
extern double SLLong          = 3.0;  // SL Buffer Long in %     (1.04)
extern double SLShort         = 3.0;  // SL Buffer Short in %    (1.04)
extern double AnzahlCFD       = 0.1;    // Anzahl Lots pro Pyramide
extern double AnzahlPyramide  = 5;    // Max. Anz Pyramide
extern int MaximalAnzahlCFD   = 50;   // Max. Anz. CFD bei Dynamik
extern double RisikoWert      = 5;    // Risikowert (%) auf Gesamtbudget
extern int HandelsPausevonHH  = 0;    // Handelspause HH ab
extern int HandelsPausevonMM  = 0;    // Handelspause MM ab
extern int HandelsPausebisHH  = 0;    // Handelspause HH bis
extern int HandelsPausebisMM  = 0;    // Handelspause MM bis
extern int HATimeFrame        = 5;    // Heiken Ashi TimeFrame
extern double MACDShort       = 12.0;    // MACD SMA kurz
extern double MACDLong        = 26.0;    // MACD SMA lang
extern double MACDPeriode     = 9.0;     // MACD Periode 
extern int STPeriode          = 8;    // ST Periode
extern int STFaktor           = 2;    // ST Faktor
extern int ATRPeriode         = 8;    // ATR Periode
extern string Trend           = "UP"; // Initial Trend UP/DOWN
extern int MagicNumber        = 197430; // Magic Number


// globale, nicht änderbare Variabeln
datetime PeriodenStartZeit;
bool NeuePeriodeBegonnen;
bool LTrade = false;
bool STrade = false;
double stopl,takeprofit,Lot,Price_Cls,OpenPrice,StopLoss,TakeProfit; // 
int LOrder,SOrder,Ticket,x; 
double AnzahlLots,MACDL1,MACDL2,MACDS1,MACDS2,MACD1,MACD2,MACD1P1,MACD1P2,MACD2P1,MACD2P2,MACD1H1,MACD2H1;
string Text = "unbelegt";
string Kommentar1,Kommentar2;
string EAName = "MACD_HeikenAshi";
int AnzahlBars;
double UpperLevel;
double LowerLevel;
bool   TrendWechsel = false;
double SuperTrend;


// globale Funktionen

  // Heiken Ashi Signale
  double GetHA(int tf, int param, int shift)
         { return(iCustom(NULL,tf,"Heiken Ashi",param,shift));}

  // MACD auf HA - Basis berechnen
  int MACD(){
            MACDL1 = GetHA(HATimeFrame,3,300);
            MACDL2 = GetHA(HATimeFrame,3,301);
            MACDS1 = GetHA(HATimeFrame,3,300);
            MACDS2 = GetHA(HATimeFrame,3,301);
            MACD1  = MACDS1 - MACDL1;
            MACD2  = MACDS2 - MACDL2;
            for(x=299; x > 0;x--){
                MACDL1 = MACDL1 + ((2/(MACDLong+1)) * (GetHA(HATimeFrame,3,x) - MACDL1));            
                MACDL2 = MACDL2 + ((2/(MACDLong+1)) * (GetHA(HATimeFrame,3,x+1) - MACDL2));       
                MACDS1 = MACDS1 + ((2/(MACDShort+1)) * (GetHA(HATimeFrame,3,x) - MACDS1));            
                MACDS2 = MACDS2 + ((2/(MACDShort+1)) * (GetHA(HATimeFrame,3,x+1) - MACDS2));
                MACD1  = MACD1  + ((2/(MACDPeriode+1)) * ((MACDS1 - MACDL1) - MACD1));
                MACD2  = MACD2  + ((2/(MACDPeriode+1)) * ((MACDS2 - MACDL2) - MACD2));                                 
            }

            return(0);
  
  }

  // Supertrend von HA berechnen          
  int STHA(){ 
            UpperLevel = ((GetHA(HATimeFrame,1,1) + GetHA(HATimeFrame,2,1)) / 2) + (STFaktor * iATR(NULL,HATimeFrame,ATRPeriode,1));
            LowerLevel = ((GetHA(HATimeFrame,1,1) + GetHA(HATimeFrame,2,1)) / 2) - (STFaktor * iATR(NULL,HATimeFrame,ATRPeriode,1));
               
            if( Trend == "UP" && GetHA(HATimeFrame,3,1) < SuperTrend && TrendWechsel == false){
                TrendWechsel = true;
                }
            if( Trend == "DOWN" && GetHA(HATimeFrame,3,1) > SuperTrend && TrendWechsel == false){
                TrendWechsel = true;
                }

            if(Trend == "UP" && TrendWechsel == false){
               if(SuperTrend < LowerLevel){SuperTrend = LowerLevel;}
            }
            if(Trend == "DOWN" && TrendWechsel == false){
               if(SuperTrend > UpperLevel){SuperTrend = UpperLevel;}
            }
            
            if(TrendWechsel){
               TrendWechsel = false;
               
               if(Trend == "UP"){
                  Print("Trendwechsel UP zu DOWN. Preis:",Bid," <<<<<<<<<<<<<<<<<<");
                  Trend = "DOWN";
                  SuperTrend = UpperLevel;
               } else{ if(Trend == "DOWN"){
                          Print("Trendwechsel DOWN zu UP. Preis:",Ask," <<<<<<<<<<<<<<<<<<");
                          Trend = "UP";
                          SuperTrend = LowerLevel;
                          }
                     }    
            }                     
            return(0);
  }  


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



if(AnzahlLots > MaximalAnzahlCFD){ AnzahlLots = MaximalAnzahlCFD;} 
else {AnzahlLots = AnzahlCFD;}
if(AnzahlLots < 0){Alert("Kein Trade möglich. Anzahl Lots mit dem angegebenen Risiko < = 0.");
                    return(0);
                  }

   Alert("ACCOUNT-BALANCE: ",AccountBalance());
   Alert("ORDER LONG:",Ask," TP: Gegensignal  SL: ",DoubleToStr(stopl,2),"oder Gegensignal. Anzahl Lots: ",AnzahlLots);
   LOrder = OrderSend(Symbol(),OP_BUY,AnzahlLots,Ask,10,stopl,takeprofit,EAName,MagicNumber,0,Green);

   return(0);
}

int ShortOrder(){

// stopl      = Bid + (iATR(NULL,0,ATRPeriode,0) * (1 + (SLShort / 100)));
stopl      = Bid * (1 + (SLShort / 100));
takeprofit = 0;


if(AnzahlLots > MaximalAnzahlCFD){ AnzahlLots = MaximalAnzahlCFD;}
else {AnzahlLots = AnzahlCFD;}
if(AnzahlLots <= 0){Alert("Kein Trade möglich. Anzahl Lots mit dem angegebenen Risiko < = 0");
                    return(0);
                   }
   Alert("ORDER SHORT:",Bid," TP: Gegensignal  SL: ",DoubleToStr(stopl,2)," oder Gegensignal");
   SOrder = OrderSend(Symbol(),OP_SELL,AnzahlLots,Bid,10,stopl,takeprofit,EAName,MagicNumber,0,Red);
       
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
//---
   PeriodenStartZeit = Time[0]; // Einmaliges Setzen des Zeitstempels
   
   STHA();
   SuperTrend = LowerLevel; // Initiales Setzens eines Trends. Wir gehen von UP aus
   Print("SuperTrend Initalwert: ",SuperTrend);
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
          if(TimeHour(TimeCurrent()) >= HandelsPausebisHH &&
             TimeHour(TimeCurrent()) <= HandelsPausebisMM &&
             TimeMinute(TimeCurrent()) >= HandelsPausevonHH &&
             TimeMinute(TimeCurrent()) <= HandelsPausevonMM){
          }
       
       // Handelssignal prüfen
       
         // Print("Heiken Ashi Close: ",GetHA(5,3,1));
         
         MACD(); // MACD bestimmen
         MACD1P1  = MACDS1 - MACDL1;   // 1. Periode MACD letzte abgeschlossene Kerze
         MACD1P2  = MACD1;             // 2. Periode MACD letzte abgeschlossene Kerze
         MACD1H1   = MACD1P1 - MACD1P2; // Histogrammwert MACD letzte abgeschlossene Kerze
         MACD2P1  = MACDS2 - MACDL2;   // 1. Periode MACD vorletzte abgeschlossene Kerze
         MACD2P2  = MACD2;             // 2. Periode MACD vorletzte abgeschlossene Kerze
         MACD2H1   = MACD2P1 - MACD2P2; // Histogrammwert MACD vorletzte abgeschlossene Kerze
         // Print("Histogrammwert letzte Kerze: ",MACD1H1);
         // Print("Histogrammwert vorletzte Kerze: ",MACD2H1);
         
         STHA(); // Supertrend bestimmen
         
         if(MACD1H1 > 0 && MACD2H1 < 0 && Trend == "UP" ){ //Cross von unter 0 nach über 0, wenn ST UP ist
           // Ggf. offene Trades schließen
           OffeneOrderSchliessen();
           LongOrder();
           Print("Order Long ausgelöst!");
           Print("Histogrammwert letzte Kerze: ",MACD1H1);
           Print("Histogrammwert vorletzte Kerze: ",MACD2H1);
         }

         if(MACD1H1 < 0 && MACD2H1 > 0 && Trend == "Down" ){ //Cross von unter 0 nach über 0
           // Ggf. offene Trades schließen
           OffeneOrderSchliessen();
           ShortOrder();
           Print("Order Short ausgelöst!");
           Print("Histogrammwert letzte Kerze: ",MACD1H1);
           Print("Histogrammwert vorletzte Kerze: ",MACD2H1);
           
         } 

 

         
/*         
         Print("UpperLevel= ",UpperLevel);
         Print("LowerLevel= ",LowerLevel);
         Print("ATR= ",iATR(NULL,HATimeFrame,ATRPeriode,0));
         Print("Trend = ",Trend," SuperTrend = ",SuperTrend);
*/         
   
   }
  }
//+------------------------------------------------------------------+
