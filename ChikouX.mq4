//+------------------------------------------------------------------+
//|                                                      ChikouX.mq4 |
//|             Stephan Benik, nach einer Tradingidee von Cheftrader |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Stephan Benik V0.1, nach einer Tradingidee von Cheftrader"
#property link      ""
#property version   "1.00"
#property strict

// globale EXTERN einstellbar Variablen
extern int Chikou_lang = 38; // Verzögerung Darstellung 
extern int Chikou_kurz = 26; // Verzögerung Darstellung 
extern double SL_Close   = 0.53; // %ualer SL-Abstand zum Basiswert des Instruments zum Close-Preis der Periode
extern double SL_Preis   = 0.7;  // %ualer SL-Abstand zum Basiswert des Instruments zum Marktpreis (um bei Sell-Offs kein Gap zu bekommen)
extern int Periode = 15;

// globale Variable
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
   // Auf Periodenstart prüfen
   if(PeriodenStartZeit != Time[0]){
      Print("Neue Periode begonnen ",Time[0]);
      NeuePeriodeBegonnen = true;
      PeriodenStartZeit = Time[0];
   } else { NeuePeriodeBegonnen = false; }
   
// Crash-SL außerhalb der Periode abfragen
     // time
   // Handelssignale überprüfen
   if(NeuePeriodeBegonnen == true){
      // Marktdaten ermitteln
      Print("Marktdaten ermitteln");
      double MAlang1 = iMA(NULL,Periode,1,Chikou_lang,MODE_SMA,PRICE_CLOSE,Chikou_lang-2); // 1 = 1 Periode zurück
      double MAlang2 = iMA(NULL,Periode,1,Chikou_lang,MODE_SMA,PRICE_CLOSE,Chikou_lang-1); 
      double MAlang3 = iMA(NULL,Periode,1,Chikou_lang,MODE_SMA,PRICE_CLOSE,Chikou_lang); 
      double MAlang4 = iMA(NULL,Periode,1,Chikou_lang,MODE_SMA,PRICE_CLOSE,Chikou_lang+1);
      double MAkurz1 = iMA(NULL,Periode,1,Chikou_kurz,MODE_SMA,PRICE_CLOSE,Chikou_kurz-2); // 1 = 1 Periode zurück
      double MAkurz2 = iMA(NULL,Periode,1,Chikou_kurz,MODE_SMA,PRICE_CLOSE,Chikou_kurz-1); 
      double MAkurz3 = iMA(NULL,Periode,1,Chikou_kurz,MODE_SMA,PRICE_CLOSE,Chikou_kurz); 
      double MAkurz4 = iMA(NULL,Periode,1,Chikou_kurz,MODE_SMA,PRICE_CLOSE,Chikou_kurz+1); 
      
      Print("MAlang1: ",MAlang1);
      Print("MAlang2: ",MAlang2);
      Print("MAlang3: ",MAlang3);
      Print("MAlang4: ",MAlang4);
      Print("MAkurz1: ",MAkurz1);
      Print("MAkurz2: ",MAkurz2);
      Print("MAkurz3: ",MAkurz3);
      Print("MAkurz4: ",MAkurz4);

      if(MAkurz1 == 0 ||
         MAkurz2 == 0 ||
         MAkurz3 == 0 ||
         MAkurz4 == 0 ||
         MAlang1 == 0 ||
         MAlang2 == 0 ||
         MAlang3 == 0 ||
         MAlang4 == 0
      ){ Alert("Ein Wert fehlt! V0.2");
         }
      // Long  Signal (38er kreuzt 26er von unten nach oben und muss bestätigt werden) 
      if(MAkurz1 < MAlang1 &&
         MAkurz2 < MAlang2 &&
         MAkurz3 < MAlang3 &&
         MAkurz4 > MAlang4 &&
         MAlang1 > MAlang2 &&
         MAlang2 > MAlang3 &&
         MAlang3 > MAlang4 &&
         MAkurz4 > MAkurz3
          ){
         
         Alert("LONG-Signal");
         
      }
      
      
      // Short Signal (38er kreuzt 26er von oben nach unten und muss bestätigt werden)      
      if(MAkurz1 > MAlang1 &&
         MAkurz2 > MAlang2 &&
         MAkurz3 > MAlang3 &&
         MAkurz4 < MAlang4 &&
         MAlang1 < MAlang2 &&
         MAlang2 < MAlang3 &&
         MAlang3 < MAlang4 &&
         MAkurz4 < MAkurz3
          ){
          Alert("SHORT-Signal");         
          
          }
      
   }   
   
   
  } // Ende OnTick
//+------------------------------------------------------------------+
