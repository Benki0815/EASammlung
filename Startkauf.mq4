//+------------------------------------------------------------------+
//|                                                    Startkauf.mq4 |
//|                                                    Stephan Benik |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Stephan Benik"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

datetime PeriodenStartZeit;
bool NeuePeriodeBegonnen;
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
   if(PeriodenStartZeit != Time[0]){
         Print("Neue Periode begonnen ",Time[0]);
         NeuePeriodeBegonnen = true;
         PeriodenStartZeit = Time[0];
      } else { NeuePeriodeBegonnen = false; }
      
     
     
   if(NeuePeriodeBegonnen == true){
      // Marktdaten ermitteln
      
      
   }
   
   } // Ende onTick
//+------------------------------------------------------------------+
