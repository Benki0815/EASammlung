//+--------------------------------------------------------------------+
//|                                                   8-9Rebound.mq4   |
//|                                    Copyright 2016, Stephan Benik   |
//|                                                                    |
//|        Ab 8h 5 Anteile SHORT, wenn DAX über 15 Punkte gestiegen    |
//| Ab 8h 3 Anteile SHORT, wenn DAX über 20 Punkte gestiegen           |
//| Ab 8h 2 Anteile SHORT, wenn DAX über 25 Punkte gestiegen           |
//| Ab 8h 1 Anteile SHORT, wenn DAX über 30 Punkte gestiegen           |
//|                                                                    |
//| Ab 8h 5 Anteile LONG, wenn DAX über 15 Punkte gefallen             |
//| Ab 8h 3 Anteile LONG, wenn DAX über 20 Punkte gefallen             |
//| Ab 8h 2 Anteile LONG, wenn DAX über 25 Punkte gefallen             |
//| Ab 8h 1 Anteile LONG, wenn DAX über 30 Punkte gefallen             |
//|                                                                    |
//| Pending Orders löschen, wenn bis 9h nicht gefüllt                  |
//| Trade schließen, wenn 8h-Kurs erreicht ist                         |
//| Wenn 8h-Kurs nicht mehr erreicht wird, Schließen nach Zeit bzw. SL |
//+--------------------------------------------------------------------+
#property copyright "Copyright 2016, Stephan Benik"
#property link      ""
#property version   "1.01"
#property strict

// globale, änderbare Variablen

extern double SLLong          = 50;  // SL Long 
extern double SLShort         = 50;  // SL Short
extern bool   Dynamik         = false; // Anzahl CFDs nach Budget
extern double AnzahlCFD       = 0.1;    // Anzahl der CFDs (fest)
extern int Anteile1           = 5;    // Anteile erste Stufe
extern int Anteile2           = 3;    // Anteile erste Stufe
extern int Anteile3           = 2;    // Anteile erste Stufe
extern int Anteile4           = 1;    // Anteile erste Stufe
extern int Schwellwert1       = 15;   // Schwellwert 1 in Punkten
extern int Schwellwert2       = 20;   // Schwellwert 2 in Punkten
extern int Schwellwert3       = 25;   // Schwellwert 3 in Punkten
extern int Schwellwert4       = 30;   // Schwellwert 4 in Punkten
extern int MaximalAnzahlCFD   = 50;   // Max. Anz. CFD bei Dynamik
extern int HandelvonHH        = 7;    // Handel von HH
extern int HandelvonMM        = 1;   // Handel von MM
extern int HandelbisHH        = 8;    // Handel bis HH
extern int HandelbisMM        = 0;    // Handel bis MM
extern int MagicNumber        = 197460; // Magic Number
extern string EAName          = "8-9Rebound"; // EA-Name für Kommentar
extern int BarsOpen           = 1;    // Bars zurück für OpenPreis
extern int SecExpire          = 3535; // Nach x Sek. Order löschen


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
bool OrdersPlatzieren = true;
datetime ExpirationTime;
bool OppositClosed = false;
int OrderCount = 0;

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

int LongOrder(int Schwellwert, int Anteile){

stopl      = iOpen(NULL,PERIOD_M1,BarsOpen) - Schwellwert - SLShort; 
AnzahlLots = AnzahlCFD * Anteile;
if(AnzahlLots < 0){Alert("Kein Trade möglich. Anzahl Lots mit dem angegebenen Risiko < = 0.");
                    return(0);
}

   ExpirationTime = TimeCurrent()+ SecExpire;
   Print("BUY_LIMIT: AnzahlLots: ",AnzahlLots," Bid+Schwellwert: ",iOpen(NULL,PERIOD_M1,BarsOpen)-Schwellwert," Stopl: ",stopl,"Exp: ",ExpirationTime," iOpen: ",iOpen(NULL,PERIOD_M1,BarsOpen));

   LOrder = OrderSend(Symbol(),OP_BUYLIMIT,AnzahlLots,iOpen(NULL,PERIOD_M1,BarsOpen)-Schwellwert,10,stopl,iOpen(NULL,PERIOD_M1,BarsOpen),EAName,MagicNumber,ExpirationTime,Green);
   if(LOrder != -1){
      Trade = "LONG";
      PlaySound("bulup.wav");
   } else {Print("Order-Fehler: ",GetLastError());}

   return(0);
}

int ShortOrder(int Schwellwert, int Anteile){

stopl      = iOpen(NULL,PERIOD_M1,BarsOpen) + Schwellwert + SLShort;

AnzahlLots = AnzahlCFD * Anteile;
if(AnzahlLots <= 0){Alert("Kein Trade möglich. Anzahl Lots mit dem angegebenen Risiko < = 0");
                    return(0);
}

   ExpirationTime = TimeCurrent()+ SecExpire;
   Print("SELLLIMIT: AnzahlLots: ",AnzahlLots," Bid+Schwellwert: ",iOpen(NULL,PERIOD_M1,BarsOpen)+Schwellwert," Stopl: ",stopl,"Exp: ",ExpirationTime," iOpen: ",iOpen(NULL,PERIOD_M1,BarsOpen));
   SOrder = OrderSend(Symbol(),OP_SELLLIMIT,AnzahlLots,iOpen(NULL,PERIOD_M1,BarsOpen)+Schwellwert,10,stopl,iOpen(NULL,PERIOD_M1,BarsOpen),EAName,MagicNumber,ExpirationTime,Red);
   if(SOrder != -1){
      Trade = "SHORT";
      PlaySound("bulup.wav");
   } else {Print("Order-Fehler: ",GetLastError());}
       
   return(0);
}

int CheckPending(){ // Check if pending orders trickert 
   for(int i=1; i <= OrdersTotal(); i++){
      if(OrderSelect(i-1,SELECT_BY_POS) == true){
         if(OrderSymbol() == Symbol() &&
            OrderMagicNumber() == MagicNumber){
               // Check for triggered pending Order
               if(OrderType() == OP_BUY){ //Found a BUY-Order > Cancel ALL SELL-Orders
                  CloseSellOrders();
                  OppositClosed = true;
                  return(0);
               }
               if(OrderType() == OP_SELL){ //Found a SELL-Order > Cancel ALL BUY-Orders
                  CloseBuyOrders();
                  OppositClosed = true;
                  return(0);
               }
         }
      }
   return(0); 
   }
   return(0); 
}

int CloseBuyOrders(){ 
   OrderCount = 0;
   for(int i=1; i <= OrdersTotal(); i++){
      if(OrderSelect(i-1,SELECT_BY_POS) == true){
         if(OrderSymbol()      == Symbol() &&
            OrderMagicNumber() == MagicNumber &&
            OrderType()        == OP_BUYLIMIT){
               int Delete = OrderDelete(OrderTicket());
               OrderCount++;
               i--;
            } // End if (OrderSymb..
      } // End if (Orderselect)
   } // End for
 Print(OrderCount," BUY-Limit Order(s) gelöscht");
 return(0); 
} // End CloseBuyOrders

int CloseSellOrders(){ 
   OrderCount = 0;
   for(int i=1; i <= OrdersTotal(); i++){
      if(OrderSelect(i-1,SELECT_BY_POS) == true){
         if(OrderSymbol()      == Symbol() &&
            OrderMagicNumber() == MagicNumber &&
            OrderType()        == OP_SELLLIMIT){
               int Delete = OrderDelete(OrderTicket());
               OrderCount++;
               i--;
            } // End if (OrderSymb..
      } // End if (Orderselect)
   } // End for
 Print(OrderCount," SELL-Limit Order(s) gelöscht");
 return(0); 
} // End CloseBuyOrders


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
   
   
   /*
   
   Auf Timeframe 1M setzen bei
   
   
   */
   
   if(NeuePeriodeBegonnen == true){
  
       // Handelzeiten prüfen
          if(TimeHour(TimeCurrent()) == HandelvonHH &&
             TimeMinute(TimeCurrent()) == HandelvonMM ){
          
               if(OrdersPlatzieren){
               
                  LongOrder(Schwellwert1,Anteile1);
                  LongOrder(Schwellwert2,Anteile2);
                  LongOrder(Schwellwert3,Anteile3);
                  LongOrder(Schwellwert4,Anteile4);
                  ShortOrder(Schwellwert1,Anteile1);
                  ShortOrder(Schwellwert2,Anteile2);
                  ShortOrder(Schwellwert3,Anteile3);
                  ShortOrder(Schwellwert4,Anteile4);
                  OrdersPlatzieren = false;
                  OppositClosed = false;

               }

         } // Handelszeiten
         
      // Wieder scharf schalten
         if(TimeHour(TimeCurrent()) == HandelvonHH &&
            TimeMinute(TimeCurrent()) == HandelvonMM+1 ){ // Eine Minute nach Tradeplatzierung 
             OrdersPlatzieren = true;
             } // End if
      
         
        // Pending Orders auf Ausführung prüfen
        if(OppositClosed == false) CheckPending();

     }
      
  }
//+------------------------------------------------------------------+
