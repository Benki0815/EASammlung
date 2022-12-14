//+------------------------------------------------------------------+
//|                                          MomentumRSITrader.mq4   |
//|                                    Copyright 2021, Stephan Benik |
//|                                 Version 0.01, 26.04.2022 - 18:04 |
//|                                                                  |
//| Signal:                                                          |
//| Momentum kreuzt die 100er Linie und RSI ist entweder > 50 f. LONG|
//| oder < 50 für SHORT                                              |
//|                                                                  |
//| Start Trade: wenn Signal nach jeder Kerze in diese Richtung      |
//|              solange bis max. Lot erreicht                       |
//|                                                                  |
//|                                                                  |
//| Stop Trade:                                                      |
//| EA stoppt optional bei Gegensignal oder bei Erreichen des SL     |
//|                                                                  |
//|                                                                  |
//| Initial-SL: High/Low der letzten 2 Kerzen                        |
//| Trailing SL: High/Low der letzten 3 Kerzen                       |
//| Wenn RSI > 70 SL High/Low der letzten Kerze                      |
//|                                                                  |
//| Exit Strategie 1 = Wenn RSI über Upper/Lower kurzen TSL, sonst   |
//|                    normalen TSL                                  |
//| Exit Strategie 2 = Jede Gewinnkerze über Level x wird verkauft   |
//|                    Verlusttrades werden gehalten bis SL          |
//|                                                                  |
//| Exit Strategie 3 = RSI Umkehrsignal                              |
//|                                                                  |
//|                                                                  |
//|                                                                  |
//|                                                                  |
//| Symbole: Zunächst EURUSD M15,                                    |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Stephan Benik"
#property link      ""
#property version   "101.001"
#property strict

// globale, änderbare Variablen

sinput string line1           = "===== TIMES ==========================="; // Times
extern int    TFPivot         = 15;   // 
extern int    TradingHHStart  = 0;    // Trading HH Start
extern int    TradingHHEnd    = 23;   // Trading HH End
sinput string line            = "===== EXIT STRATEGY ===================="; // SL-BEHAVIOUR
extern int    ExitStrategie   = 3;    // Exit Strategy (0 = off)
extern bool   CancelGegenSignal   = true; // Cancel open trades when opposit Signal?
extern int    TSLXBars        = 2;    // TSL x Bars 0=off
extern int    SLBuffer        = 5;   // SL point+ x Buffer
extern int    RSIUpperLevel    = 70;    // RSI upper threshold
extern int    RSILowerLevel    = 30;    // RSI lower threshold
extern int    RSISLPeriode     = 14; // RSI SL Periode 
extern int    FixTP            = 0;   // Fix TP in Pips 0 = off
extern int    TPExit2          = 20;  // Exit 2 TP in Pips
extern double SARStep          = 0.015; // SAR Step (0.02)
extern double SARMax           = 0.2;   // SAR Max  (0.2)
sinput string line2            = "===== Trade Start Buffers,  Sensitivity and Signals ====="; // Trade Start Buffers,  Sensitivity and Signals
extern bool   MomRSI           = false; // Momentum and RSI Crosscheck
extern int    MomPeriode       = 14;   // Momentum Periode (def. 14)
extern int    RSIPeriode       = 14;   // RSI Periode (def. 14)
extern int    RSIOrderPeriode  = 14;   // RSI Order Periode (def. 14)
extern int    RSIPivotPoint    = 14;   // RSI Pivot Point (def. 50)
extern int    MAShift          = 5;    // MA TrendSignal Shift
extern bool   SARTrading       = true; // Parabolic SAR & RSI-Trend
sinput string line3            = "===== MONEY MANAGEMENT ===================="; // Money Management
extern bool   TradingOn        = false; // Trading activated?
extern double AnzahlCFD        = 0.01;    // No. of lots
extern int MaxTradesTotal      = 10;    // Max trades in total   
sinput string line4            = "===== HELPERS ========= ===================="; //Helpers
extern string EAName           = "MomentumRSITrader"; // EA-Name
extern int MagicNumber         = 19742203; // Magic-Number NOT EMPTY!
extern bool   DebugComments    = true;  // Debug Comments
extern int    AngleDnText      = 70;    // Down-Text Angle 45-180 (70)
extern int    AngleUpText      = 290;   // Down-Text Angle 180-360 (290)
extern bool   DrawSignalRect   = true;  // Draw rectangle around signal candles


// globale, nicht änderbare Variabeln
datetime PeriodenStartZeit;
bool NeuePeriodeBegonnen;
bool Surveillance = false;
int EMAStatus = 0;
int    TSLXBarsCur;
double TagesSchwankung,stopl,takeprofit,Lot,Price_Cls,OpenPrice,StopLoss,TakeProfit,AnzahlLots;
int LOrder,SOrder,Ticket,StartTag; 
string Text = "unbelegt";
string Kommentar1,Kommentar2,Kommentar3,Kommentar4;
string Trade = "Flat";
double AktSpanne;
int SignalCounter = 0;
// Sounds laden
string Sound1  = "bearish_engulfing.wav";
string Sound2  = "bullish_engulfing.wav";
string Sound3  = "bearish_harami.wav";
string Sound4  = "bullish_harami.wav";
string Sound5  = "hammer.wav";
string Sound6  = "shooting_star.wav";
string Sound7  = "on_dax.wav";
string Sound8  = "on_eur-usd.wav";
string Sound9  = "on_dow_jones.wav";
string Sound10 = "on_sp500.wav";
string Sound11 = "starting_longtrade.wav";
string Sound12 = "starting_short_trade.wav";
string Sound13 = "morning_star.wav";
string Sound14 = "evening_star.wav";
string Sound15 = "on_chfjpy.wav";
string Sound16 = "atari66.wav";


// -----------------------------------------------------------------------------------
// globale Funktionen
// -----------------------------------------------------------------------------------

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

void Kommentare_loeschen(){
   ObjectDelete("comment_zeile1");
   ObjectDelete("comment_zeile2");
   ObjectDelete("comment_zeile3");
   ObjectDelete("comment_zeile4");   
   WindowRedraw();
}

void drawProfit(double LastProfit){
   string name = "Profit"+Bars;
   string nameText = "Text"+name;
   string LastProfitText = DoubleToStr(LastProfit,8);
   double Vertical_Offset= Point*90;
   string Horizontal_Offset = "    ";
   ObjectCreate(name,OBJ_RECTANGLE_LABEL, 0, Time[0], Close[0]); //draw a dn arrow
   ObjectSet(name, OBJPROP_XSIZE, 40);
   ObjectSet(name, OBJPROP_YSIZE, 20);
   ObjectSet(name, OBJPROP_FONT, "Arial");
   ObjectSet(name, OBJPROP_FONTSIZE, 8);
   ObjectSet(name, OBJPROP_BACK, FALSE);
   ObjectSet(name, OBJPROP_SELECTED,FALSE);
   ObjectSet(name, OBJPROP_SELECTABLE,FALSE);
   ObjectSet(name, OBJPROP_TEXT,LastProfitText);
   ObjectSet(name, OBJPROP_COLOR,clrWhite);
   ObjectSet(name, OBJPROP_BGCOLOR,clrPurple);
  
}

void drawDnArrow(string arrowText){
   string name = "Dn"+Bars;
   string nameText = "Text"+name;
   double Vertical_Offset= Point*90;
   string Horizontal_Offset = "                         ";
   ObjectCreate(name,OBJ_ARROW, 0, Time[1], High[1]+40*Point); //draw a dn arrow
   ObjectSet(name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet(name, OBJPROP_ARROWCODE, SYMBOL_ARROWDOWN);
   ObjectSet(name, OBJPROP_COLOR,Red);
   // display Text above arrow 
   ObjectCreate(nameText, OBJ_TEXT, 0, Time[1], High[1]+ Vertical_Offset);
   ObjectSetText(nameText,Horizontal_Offset+arrowText,10,"Verdana", Red);
   ObjectSet(nameText,OBJPROP_ANGLE,AngleDnText);
   Sound(99);Sleep(300);
}

void drawUpArrow(string arrowText){
   string name2 = "Up"+Bars;
   string nameText = "Text"+name2;
   double Vertical_Offset= Point*80;
   string Horizontal_Offset = "                         ";
   ObjectCreate(name2,OBJ_ARROW, 0, Time[1], Low[1]-40*Point); //draw a up arrow
   ObjectSet(name2, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet(name2, OBJPROP_ARROWCODE, SYMBOL_ARROWUP);
   ObjectSet(name2, OBJPROP_COLOR,Green);
   // display Text below arrow 
   ObjectCreate(nameText, OBJ_TEXT, 0, Time[0],Low[1]-Vertical_Offset);
   ObjectSetText(nameText,Horizontal_Offset+arrowText,10,"Verdana", Green);
   ObjectSet(nameText,OBJPROP_ANGLE,AngleUpText);
   Sound(99);
}

void drawRectangle(int barsBack, bool up){
   string objName = "Rect"+Bars;
   string bColor = "clrRed";
   if (up){ bColor = "clrGreen"; }
   ObjectCreate(objName, OBJ_RECTANGLE, 0, Time[0], Low[barsBack]-20*Point, Time[barsBack+1], High[barsBack]+20*Point);
   ObjectSet(objName, OBJPROP_BACK, false);
   ObjectSet(objName, OBJPROP_BORDER_COLOR, bColor);
}


void Sound(int SoundNr){
   switch(SoundNr)
   {
      case 1:  PlaySound(Sound1); break; // BearEngulfing
      case 2:  PlaySound(Sound2); break; // BullEngulfing
      case 3:  PlaySound(Sound3); break; // BearHarami
      case 4:  PlaySound(Sound4); break; // BullHarami
      case 5:  PlaySound(Sound5); break; // Hammer
      case 6:  PlaySound(Sound6); break; // Shooting Star
      case 11: PlaySound(Sound11); break; // Start LONG
      case 12: PlaySound(Sound12); break; // Start SHORT
      case 13: PlaySound(Sound13); break; // MStar
      case 14: PlaySound(Sound14); break; // EStar
      case 16: PlaySound(Sound16); break; // Beep
      case 99: PlaySound("message.wav"); break;
   }
  Sleep(1200);
}

void SoundSignal() {
   if ( Symbol() == "DAX40" ) { PlaySound(Sound7); }
   if ( Symbol() == "EURUSD" ){ PlaySound(Sound8); }
   if ( Symbol() == "WS30" )  { PlaySound(Sound9); }
   if ( Symbol() == "SP500" ) { PlaySound(Sound10); }
   if ( Symbol() == "CHFJPY" ) { PlaySound(Sound15); }
   Sleep(2200);
}

string Zeitstempel() {
     int h=TimeHour(TimeCurrent());
     int m=TimeMinute(TimeCurrent());
     int s=TimeSeconds(TimeCurrent());
     string currtime = "";
     if( h < 10 ){ currtime = "0" + IntegerToString( h ); } else {currtime = IntegerToString( h );}
     currtime = currtime+":";
     if( m < 10 ){ currtime = currtime + "0" + IntegerToString( m ); } else {currtime = currtime + IntegerToString( m );}
     currtime = currtime+":";
     if( s < 10 ){ currtime = currtime + "0" + IntegerToString( s ); } else {currtime = currtime + IntegerToString( s );} 
     return(currtime);
}

// Muster erkennen


bool MomentumRSICheckLong(){
   
   if (  iMomentum(NULL,0,MomPeriode,PRICE_CLOSE,0) > 100 &&
         iMomentum(NULL,0,MomPeriode,PRICE_CLOSE,1) < 100 &&
         iRSI(NULL,0,RSIPeriode,PRICE_CLOSE,0)      > 50 ){
            SignalCounter++;
            return(true);
         } else { return(false); }
}

bool MomentumRSICheckShort(){
   
   if (  iMomentum(NULL,0,MomPeriode,PRICE_CLOSE,0) < 100 &&
         iMomentum(NULL,0,MomPeriode,PRICE_CLOSE,1) > 100 &&
         iRSI(NULL,0,RSIPeriode,PRICE_CLOSE,0)      < 50 ){
            SignalCounter++;
            return(true);
         } else { return(false); }
}

// Kerzen analysieren
bool TrendUp(int backBars){
   if( iMA(NULL,0,MAShift,0,MODE_EMA,PRICE_CLOSE,backBars) > iMA(NULL,0,MAShift,0,MODE_EMA,PRICE_CLOSE,backBars+1) ){
         return(true);
      }  else { return(false);
         }
}

bool weisseKerze(int backBars){ //Weiße Kerze = true, schwarze kerze = false
    if ( iClose(NULL,0,backBars) > iOpen(NULL,0,backBars) ){
    return(true); // weiss
    } else {return(false);} //schwarz
}

bool xBarsWhite(int shift, int backBars){ // 2, 3 = ab Kerze zwei für drei Kerzen
   bool weiss = true;
   while( backBars > 0 ){
      if( !weisseKerze( shift + backBars - 1 ) ) { weiss = false; }
      backBars--;
   }
   return( weiss );
}

bool xBarsBlack(int shift, int backBars){ // 2, 3 = ab Kerze zwei für drei Kerzen
   bool black = true;
   while( backBars > 0 ){
      if( weisseKerze( shift + backBars - 1 ) ) { black = false; }
      backBars--;
   }
   return( black );
}

bool xBarsTrendUp(int shift, int backBars){ // 2, 3 = ab Kerze zwei für drei Kerzen
   bool trend = true;
   while( backBars > 0 ){
      if( !TrendUp( shift + backBars - 1 ) ) { trend = false; }
      backBars--;
   }
   return( trend );
}

bool xBarsTrendDn(int shift, int backBars){ // 2, 3 = ab Kerze zwei für drei Kerzen
   bool trend = true;
   while( backBars > 0 ){
      if( TrendUp( shift + backBars - 1 ) ) { trend = false; }
      backBars--;
   }
   return( trend );
}

double KerzenLaenge(int backBars){ 
    if (weisseKerze(backBars)){
    return( iClose(NULL,0,backBars) - iOpen(NULL,0,backBars) );
    } else {return( iOpen(NULL,0,backBars) - iClose(NULL,0,backBars) );}
}

double DochtLaenge(int backBars){ 
    if (weisseKerze(backBars)){
    return( iHigh(NULL,0,backBars) - iClose(NULL,0,backBars) );
    } else {return( iHigh(NULL,0,backBars) - iOpen(NULL,0,backBars) );}
}

double LuntenLaenge(int backBars){ 
    if (weisseKerze(backBars)){
    return( iOpen(NULL,0,backBars) - iLow(NULL,0,backBars) );
    } else {return( iClose(NULL,0,backBars) - iLow(NULL,0,backBars) );}
}


int DigitsToPips(double Umrechnungswert){
   return(MathRound(Umrechnungswert*MathPow(10,Digits))); 
}

int KerzenLaengeToPips(int backBars){
   return(MathRound(KerzenLaenge(backBars)*MathPow(10,Digits))); 
}


///////////////////////////////////////////////////////////////////
////////              PRICE SETTINGS                    ///////////
///////////////////////////////////////////////////////////////////

double SLLastX(int Richtung, int AnzBars){
   double SL;
   if( Richtung == 0 ){
     SL = iLow(NULL,0,iLowest(NULL,0,MODE_LOW,AnzBars,0));     
     Print("SL: ",SL);
     return(SL);
   }
   if( Richtung == 1 ){
     SL = iHigh(NULL,0,iHighest(NULL,0,MODE_HIGH,AnzBars,0));
     Print("SL: ",SL);
     return(SL);
   }
   return(0);
}



///////////////////////////////////////////////////////////////////
////////   ORDER FUNCTIONS                              ///////////
///////////////////////////////////////////////////////////////////

double ActiveOrders(int direction){
   double AmountOrders = 0.0;
   string Symb=Symbol();                        // Symbol
   // if ( DebugComments ) { Print("Symbol: "+Symb); }
   // if ( DebugComments ) { Print("Direction: "+direction); }
   for(int i=1; i<=OrdersTotal(); i++)          // Order searching cycle
     {
      if (OrderSelect(i-1,SELECT_BY_POS)==true) // If the next is available
        {                                       // Order analysis:
         //----------------------------------------------------------------------- 1 --
         if ( DebugComments ) { 
            // Print("OrderMagicNumber: "+OrderMagicNumber());
            // Print("OrderSymbol: "+OrderSymbol());
         }
         if (OrderSymbol()== Symbol() && OrderMagicNumber() == MagicNumber ) {
                  if (OrderType() == direction) {
                        AmountOrders += OrderLots();
                        // Print("OrderLots: "+OrderLots());
                     }
        }                                       //End of order analysis
      } 
   }
  return(AmountOrders);
}


int LongOrder(){
   double TakeProfit;
   if ( SLBuffer > 0 ) {
      stopl = iLow(NULL,0,1) - ( SLBuffer * Point );
   } else { stopl = 0; }
   if ( FixTP > 0 ) {
      TakeProfit = Bid + ( FixTP * Point );
   } else { TakeProfit = 0;}
   
   AnzahlLots = AnzahlCFD;
   if(AnzahlLots < 0){Alert("Kein Trade möglich. Anzahl Lots < = 0 ");
                       return(0);
   }
      LOrder = OrderSend(Symbol(),OP_BUY,AnzahlLots,Ask,10,stopl,TakeProfit,EAName,MagicNumber,0,Green);
      if(LOrder == -1){Print("Order-Fehler: ",GetLastError());}
        else {Print("Order: "+Symbol()+" | StopLoss: "+stopl+" | TakeProfit: "+TakeProfit);}
      return(0);
}

int ShortOrder(){

   double TakeProfit;
   if ( SLBuffer > 0 ) {
      stopl = iHigh(NULL,0,1) + ( SLBuffer * Point );
   } else { stopl = 0; }
   
   if ( FixTP > 0 ) {
         TakeProfit = Bid - ( FixTP * Point );
      } else { TakeProfit = 0;}
   AnzahlLots = AnzahlCFD;
   if(AnzahlLots <= 0){Print("Kein Trade möglich. Anzahl Lots = 0");
                       return(0);
   }
      SOrder = OrderSend(Symbol(),OP_SELL,AnzahlLots,Bid,10,stopl,TakeProfit,EAName,MagicNumber,0,Red);
      if(SOrder != -1){Print("Order-Fehler: ",GetLastError());}      
         else {Print("Order: "+Symbol()+" | StopLoss: "+stopl+" | TakeProfit: "+TakeProfit);}
      return(0);
}


int OffeneOrderSchliessen(int direction, int ExitNr){         // 0 = LONG | 1 = SHORT
    
   string Symb=Symbol();                        // Symbol
   double Dist=1000000.0;                       // Presetting
   int Real_Order=-1;                           // No market orders yet
   double Win_Price=WindowPriceOnDropped();     // The script is dropped here
   bool CloseTrade = false;
   bool Ans = false;

//-------------------------------------------------------------------------------- 2 --

   for(int i=1; i<=OrdersTotal(); i++)          // Order searching cycle
     {
      if (OrderSelect(i-1,SELECT_BY_POS)==true) // If the next is available
        {                                       // Order analysis:
         //----------------------------------------------------------------------- 3 --
         if ( OrderSymbol()!= Symb || OrderMagicNumber() != MagicNumber ) continue;      // Symbol is not ours
         if ( OrderType() > 1 || OrderType() != direction ) continue;                      // Pending order or wrong dircetion  
         //----------------------------------------------------------------------- 4 --
         double Price=OrderOpenPrice();         // Order price
         if (NormalizeDouble(MathAbs(Price-Win_Price),Digits)< //Selection
            NormalizeDouble(Dist,Digits))       // of the closest order       
           {
            Dist=MathAbs(Price-Win_Price);      // New value
            Real_Order=OrderType();                     // Market order available
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
      
       if ( ExitNr == 2 && direction == 0) {
         if ( iClose(NULL,0,1) > (TPExit2*Point) + OrderOpenPrice() ){ 
            CloseTrade = true;
         }
       }
       if ( ExitNr == 2 && direction == 1) {
         if ( iClose(NULL,0,1) <  OrderOpenPrice() - (TPExit2*Point) ){
            CloseTrade = true;
         }
       }  
       
       if ( ExitNr == 3 && direction == 0 ){
            if ( iSAR(NULL,0,SARStep,SARMax,0) > iClose(NULL,0,1) ) { CloseTrade = true;}
       }
       
       if ( ExitNr == 3 && direction == 1 ){
            if ( iSAR(NULL,0,SARStep,SARMax,0) < iClose(NULL,0,1) ) { CloseTrade = true;}
       }
       
       
       if ( ExitNr == 0 ) { CloseTrade = true; }
       
       if ( CloseTrade ){
         Print("Versuche ",Text," ",Ticket," zu schließen. Warte auf Antwort...");
         Ans=OrderClose(Ticket,Lot,Price_Cls,2);// Order closing
       }
      //-------------------------------------------------------------------------- 8 --
      if ( Ans )                            // Got it! :)
        {
         Print (Text," geschlossen ",Ticket);
         Trade="Flat";
         drawProfit(LastOrderClosedProfit());
         Print ("Letzter Profit:"+ LastOrderClosedProfit());
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
  
  
double LastOrderClosedProfit()
{
   int      ticket      =-1;
   datetime last_time   = 0;
   for(int i=OrdersHistoryTotal()-1;i>=0;i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)&&OrderSymbol()==_Symbol&&OrderCloseTime()>last_time)
      {
         last_time = OrderCloseTime();
         ticket = OrderTicket();
      }
   }
   if(!OrderSelect(ticket,SELECT_BY_TICKET))
   {
      Print("OrderSelectError: ",GetLastError());
      return 0.0;
   }    
   return OrderProfit();
}

void TrailingAlls(int TrailingBars)
  {

//----
   double stopcrnt,TPCrnt;
   double stopNew = 0;
   bool IsOrder;
   int trade, OrderResponse;
   int trades=OrdersTotal();
   int Tip;
   for( trade=0; trade < trades; trade++ )
     {
      IsOrder = OrderSelect(trade,SELECT_BY_POS,MODE_TRADES);
      if( OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber )
         {
         Tip=OrderType();
         stopcrnt = OrderStopLoss();
         TPCrnt = OrderTakeProfit();
         if ( DebugComments ) {
            Print("Wert TrailingBars in TrailingAlls: "+TrailingBars);
            Print("Stopcrnt: "+stopcrnt);
            }
         
         //LONG
            if( Tip == OP_BUY ){ 
               // Aktuellen und neuen SL ermittlen
               
               if ( TrailingBars > 0 ) {
                  if ( (SLLastX(0,TrailingBars) - (SLBuffer * Point) ) > stopcrnt || stopcrnt == 0 ) {
                        stopNew = SLLastX(0,TrailingBars) - (SLBuffer * Point); 
                        if ( DebugComments ) {Print("Neuer Stop: "+stopNew);}
                  }
               }
               
               if ( stopNew > 0 )
                 {
                  OrderResponse = OrderModify(OrderTicket(),OrderOpenPrice(),stopNew,TPCrnt,0,Red);
                  Print("Order modified: StopNew: "+stopNew+" | StopCrnt: "+stopcrnt);
                 }
            }//LONG
         
         //SHORT
            if( Tip == OP_SELL ){ 
               // Aktuellen und neuen SL ermittlen
               if ( TrailingBars > 0 ) {
                  if ( (SLLastX(1,TrailingBars) + (SLBuffer * Point) ) < stopcrnt || stopcrnt == 0 ) {
                     stopNew = SLLastX(1,TrailingBars) + (SLBuffer * Point); 
                  }
               }
               
               if ( stopNew > 0 )
                 {
                  OrderResponse = OrderModify(OrderTicket(),OrderOpenPrice(),stopNew,TPCrnt,0,Red);
                  Print("Order modified: StopNew: "+stopNew+" | StopCrnt: "+stopcrnt+" | OrederResponse: "+OrderResponse);
                 }
            }//SHORT
         }
     }
     
  }//Exit Trailing
  

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
/*
void OnDeinit()
  {
   
  }
*/
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
 // indiTest();
  
// Auf Periodenstart prüfen
   if(PeriodenStartZeit != Time[0]){
      NeuePeriodeBegonnen = true;
     // PeriodenNullsetzen();
      PeriodenStartZeit = Time[0];
   } else { NeuePeriodeBegonnen = false; }
   
   if(NeuePeriodeBegonnen == true){
   
     //////////////////////////////////////////
     // Check SL / Close
     //////////////////////////////////////////          
   
   if ( OrdersTotal() > 0 ) {
       if ( ExitStrategie == 1) {     
        // Print("Wert TSLXBars in Check SL: "+TSLXBars); 
          
        // SL for LONG
        if ( ActiveOrders(0) > 0 ){
            if ( iRSI(NULL,0,RSISLPeriode,PRICE_CLOSE,0) > RSIUpperLevel ) {
                     TSLXBarsCur = 1;
            } else { TSLXBarsCur = 2;} // TSLXBarsCur = TSLXBars; funktioniert nicht. Ist immer 0
              }
               
        // SL for SHORT
        if ( ActiveOrders(1) > 0 ){
            if ( iRSI(NULL,0,RSISLPeriode,PRICE_CLOSE,0) > RSIUpperLevel ) {
                   TSLXBarsCur = 1;
            } else { TSLXBarsCur = 2;}
              }   
        TrailingAlls( TSLXBarsCur );
      } // END EXIT 1
            
      
      if ( ExitStrategie == 2 ){
         // SL for LONG
         if ( ActiveOrders(0) > 0 ){
            OffeneOrderSchliessen(0,2);
            }
         if ( ActiveOrders(1) > 0 ){
            OffeneOrderSchliessen(1,2);
            }
      } // END EXIT 2
      
      if ( ExitStrategie == 3 ){
                  // SL for LONG
         if ( ActiveOrders(0) > 0 ){
             OffeneOrderSchliessen(0,3);
         }
         if ( ActiveOrders(1) > 0 ){
             OffeneOrderSchliessen(1,3);
            }
      } // END EXIT 3
   
   }   //END OrdersTotal > 0
      //Sind Handelzeiten? (ACHTUNG: Nur für neue Trades, SL muss trotzdem überwachrt werden! )
      if( TimeHour(TimeCurrent()) >= TradingHHStart &&
          TimeHour(TimeCurrent()) <= TradingHHEnd ){
          /*
          Print("Momentum 0: "+iMomentum(NULL,0,MomPeriode,PRICE_CLOSE,0)+"  Momentum 1: "+iMomentum(NULL,0,MomPeriode,PRICE_CLOSE,1) );
          Print("RSI 0: "+iRSI(NULL,0,RSIPeriode,PRICE_CLOSE,0)+"  RSI 1: "+iRSI(NULL,0,RSIPeriode,PRICE_CLOSE,1) );
          */
         if (!Surveillance){
            Kommentare_loeschen();
            Kommentare("Traiding hours! Looking for signals...","","",""); 
            Surveillance = true;
         } 
   
         if ( DebugComments ) {
            // Kommentare("Price 2 Pips: "+DigitsToPips(iClose(NULL,0,1)),"","","");
         }
         
         //////////////////////////////////////////////////////////////////////
         //                                                                  //
         // Signale checken                                                  //
         //                                                                  //
         //////////////////////////////////////////////////////////////////////
         if( MomRSI && MomentumRSICheckLong() ){
            drawUpArrow("MomRSI Cross LONG! (SIG: "+SignalCounter+")");
            drawRectangle(1, true);
            Kommentare("Traiding hours! Looking for signals...",Zeitstempel()+": Momentum & RSI Cross LONG - Signal #"+SignalCounter,"",""); 
            if ( DebugComments ) { Print("Signal MomRSI Cross LONG Nr.: "+SignalCounter); }
            Trade = "Long";
         }
         
         if( MomRSI && MomentumRSICheckShort() ){
            drawDnArrow("MomRSI Cross Short! (SIG: "+SignalCounter+")");
            drawRectangle(1, true);
            Kommentare("Traiding hours! Looking for signals...",Zeitstempel()+": Momentum & RSI Cross SHORT - Signal #"+SignalCounter,"",""); 
            if ( DebugComments ) { Print("Signal MomRSI Cross SHORT Nr.: "+SignalCounter); }
            Trade = "Short";
         }
         
         if ( SARTrading ) {
            if ( iSAR(NULL,0,SARStep,SARMax,0) < iClose(NULL,0,1) &&
                 iRSI(NULL,0,RSIPeriode,PRICE_CLOSE,0) > RSIPivotPoint &&
                 iRSI(NULL,0,RSIPeriode,PRICE_CLOSE,0) < RSIUpperLevel ){
                     Trade = "Long";
                 }
            if ( iSAR(NULL,0,SARStep,SARMax,0) > iClose(NULL,0,1) &&
                 iRSI(NULL,0,RSIPeriode,PRICE_CLOSE,0) < RSIPivotPoint &&
                 iRSI(NULL,0,RSIPeriode,PRICE_CLOSE,0) > RSILowerLevel ){
                     Trade = "Short";
                 }
         }
         
         // Trading ////////////
         
         // Kommentare("LONG Lots: "+DoubleToString(ActiveOrders(0)),"","SHORT Lots: "+DoubleToString(ActiveOrders(1)),""); // 0=OP_BUY | 1=OP_SELL
         
         // Order, if any
         
           if( TradingOn ){
               if( OrdersTotal() <= MaxTradesTotal ) {
                  // Trade = "Flat";
                  if ( Trade == "Long" ) {
                     // Falls "Trades cancels opposite" > Shorts schließen
                     if ( CancelGegenSignal ) { OffeneOrderSchliessen(1,0); }
                     // Kaufen, wenn Bedingungen erfüllt: letzte Kerze muss eine weiße sein
                     //if (  weisseKerze(1) && 
                     //      iRSI(NULL,0,RSIOrderPeriode,PRICE_CLOSE,0) > RSIPivotPoint &&
                     //      iRSI(NULL,0,RSIOrderPeriode,PRICE_CLOSE,0) < RSIUpperLevel ){
                        LongOrder();
                        Sound(16); SoundSignal();
                     //} else { Kommentare(NULL,NULL,"Last bar down. No trade!",""); }
                  }
                  if ( Trade == "Short" ) {
                     // Falls "Trades cancels opposite" > Shorts schließen
                     if ( CancelGegenSignal ) { OffeneOrderSchliessen(0, 0); }
                     // Kaufen, wenn Bedingungen erfüllt: letzte Kerze muss eine weiße sein
                     //if (  !weisseKerze(1) && 
                     //      iRSI(NULL,0,RSIPeriode,PRICE_CLOSE,0) < RSIPivotPoint &&
                     //      iRSI(NULL,0,RSIPeriode,PRICE_CLOSE,0) > RSILowerLevel ){
                        ShortOrder();
                        Sound(16); SoundSignal();
                     //} else  { Kommentare(NULL,NULL,"Last bar up. No trade!",""); }
                  }
                } else { Kommentare_loeschen();
                         Kommentare("Maximum trades exeeded. No new trade","Checking/Trailing SLs","",""); 
                       }
              }
         

    } else { if( Surveillance ) {//ENDE Handelzeiten überwachen
                 Surveillance = false;
                 Kommentare_loeschen();
                 Kommentare("No trading hours. Watching SLs. Sleeping. ZZzzzzZ","","",""); 
               }
               
               
           }
   }
   
   
  }
//+------------------------------------------------------------------+
