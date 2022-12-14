//+------------------------------------------------------------------+
//|                                                    Trendkauf.mq4 |
//|                                                    Stephan Benik |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Stephan Benik"
#property link      ""
#property version   "1.00"
#property strict

// Schulungsvideo http://www.daxsignal.de/ea-tutorial-2/ea-tutorial-2.html Minute 46

// globale EXTERN einstellbar Variablen
extern int Anzahl = 1; //Anzahl CFDs
extern int maxTrades = 1;
extern int ProzentEinsatz = 0;//0=über Anzahl CFDs
extern int Stoploss = 20; // Stoploss in Punkten
// extern int Takeprofit = 30; // TP in Punkten
// extern int Tral_Stop = 10;// Trailing distance
extern double TrailingStop = 1500;
extern int MAPeriode = 20;
extern int TrailOption = 2; //0=aus, 1=Tick, 2=Periode
extern double RSITP = 0.5; // TakeProfit bezogen auf RSI
extern bool RSISLOpt = false; // Schalter RSI-SL an/aus
extern double RSISL = 0.25; // StoppLoss bezogen auf RSI
extern int RSIFaktor = 14; // RSI-Periode
extern bool MACDBestaetigung = true;//
extern int EMA_lang = 26; // langsamer EMA
extern int EMA_kurz = 12; // schneller EMA



// globale Variable
datetime PeriodenStartZeit;
bool NeuePeriodeBegonnen;
int LOrder,SOrder;
string Text = "unbelegt";
int MagicNumber = 101090;
int offeneTrades;
bool OOLong, OOShort;
int Ticket;           // Order ticket
double Lot; 
double Price_Cls;
double takeprofit;
double stopl;



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
            }
         }
      } // END for
      return(0);
     } // END start()
     
int LongOrder(){
   if(TrailOption){
      takeprofit = 0;
   } else {takeprofit = Ask+(iRSI(NULL,0,RSIFaktor,PRICE_CLOSE,0)*RSITP);}
   
   if(RSISLOpt){
      stopl = Ask - (iRSI(NULL,0,RSIFaktor,PRICE_CLOSE,0)*RSISL); 
   } else {stopl = Ask-Stoploss;}
   
   Alert("TP: ",takeprofit,"  SL: ",stopl," RSI: ",iRSI(NULL,0,RSIFaktor,PRICE_CLOSE,0));
   
   LOrder = OrderSend(Symbol(),OP_BUY,Anzahl,Ask,10,stopl,takeprofit,"EA Trendkauf",MagicNumber,0,Red);
   return(0);
}
int ShortOrder(){
   if(TrailOption){
         takeprofit = 0;
      } else {takeprofit = Bid-(iRSI(NULL,0,RSIFaktor,PRICE_CLOSE,0)*RSITP);}
      
   if(RSISLOpt){
      stopl = Bid + (iRSI(NULL,0,RSIFaktor,PRICE_CLOSE,0)*RSISL); 
      } else {stopl = Bid+Stoploss;}   
      
   SOrder = OrderSend(Symbol(),OP_SELL,Anzahl,Bid,10,stopl,takeprofit,"EA Trendkauf",MagicNumber,0,Red);
   return(0);
}
int OrderTyp(){
   OOShort = false;
   OOLong = false;
   for(int i=1; i<=OrdersTotal(); i++)          // Order searching cycle
        {
         if (OrderSelect(i-1,SELECT_BY_POS)==true) // If the next is available
           {                                       // Order analysis:
            //----------------------------------------------------------------------- 3 --
            if (OrderSymbol()!= Symbol()) continue;    // Symbol is not ours
            if (OrderType() == 0 ){
               OOLong = true;
               return(0);
            }
            if (OrderType() == 1 ){
               OOShort = true;
               return(0);
            }
            //----------------------------------------------------------------------- 4 --
            
            //----------------------------------------------------------------------- 5 --
           }                                       //End of order analysis
           
        }                                          //End of order searching
      return(0);
   } // Ende OrderTyp

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
            Text="Buy ";                 // Text for Buy
            }
            break;                              // Из switch
         case 1: 
            {
            Price_Cls=Ask;                 // Order Sell
            Text="Sell ";                       // Text for Sell
            }
        }
      Alert("Attempt to close ",Text," ",Ticket,". Awaiting response..");
      bool Ans=OrderClose(Ticket,Lot,Price_Cls,2);// Order closing
      //-------------------------------------------------------------------------- 8 --
      if (Ans==true)                            // Got it! :)
        {
         Alert ("Closed order ",Text," ",Ticket);
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
   
   if(NeuePeriodeBegonnen == true){
      Comment(" ");
      if(maxTrades > OrdersTotal()){ 
        // Handdelssignal ermitteln
        double ma = iMA(NULL,0,MAPeriode,0,MODE_SMA,PRICE_CLOSE,0); 
        if(MACDBestaetigung){
           double macd12   = iMA(NULL,0,EMA_kurz,0,MODE_EMA,PRICE_CLOSE,0);
           double macd26   = iMA(NULL,0,EMA_lang,0,MODE_EMA,PRICE_CLOSE,0);
           double macd12s1 = iMA(NULL,0,EMA_kurz,0,MODE_EMA,PRICE_CLOSE,1);
           double macd26s1 = iMA(NULL,0,EMA_lang,0,MODE_EMA,PRICE_CLOSE,1);
           double macd12s2 = iMA(NULL,0,EMA_kurz,0,MODE_EMA,PRICE_CLOSE,2);
           double macd26s2 = iMA(NULL,0,EMA_lang,0,MODE_EMA,PRICE_CLOSE,2);
           
              if(Close[0] > ma){ //if((Close[0] > ma) && (Close[1] > ma)){
                  if(macd12   > macd26   &&
                     macd12s1 > macd26s1 &&
                     macd12s2 < macd26s2 ){
                     
                          Comment("Aktuelles Signal: LONG (MACDBest.)");
                          OrderTyp();
                          if(OOShort) OffeneOrderSchliessen();
                          LongOrder(); 
                       }
              }
              
              if(Close[0] < ma){
                  if(macd12   < macd26   &&
                     macd12s1 < macd26s1 &&
                     macd12s2 > macd26s2 ){
                     
                          Comment("Aktuelles Signal: SHORT (MACDBest.)");
                          OrderTyp();
                          if(OOLong) OffeneOrderSchliessen();
                          ShortOrder(); 
                       }
              }
           
           
           
           
           } else {
                    if(Close[0] > ma){
                       Comment("Aktuelles Signal: LONG ");
                       OrderTyp();
                       if(OOShort) OffeneOrderSchliessen();
                       LongOrder(); 
                    }
                    if(Close[0] < ma){
                       Comment("Aktuelles Signal: SHORT");
                       OrderTyp();
                       if (OOLong) OffeneOrderSchliessen();
                       ShortOrder(); 
                    }           
                  }
         
      }
      if(TrailOption == 2) trailing(); // Trailing Periode
      
    } // END if(NeuePeriodeBegonnen   
    if(TrailOption == 1) trailing(); // Trailing Tick
  } // END onTick
//+------------------------------------------------------------------+
