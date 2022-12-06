//+------------------------------------------------------------------+
//|                                                 Billy expert.mq4 |
//|                              Copyright © 2008, Billionaire prod. |
//|                                                 ulanenko@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2008, Billionaire prod."
#property link      "ulanenko@mail.ru"


extern int    TrailingStop   = 30;
extern int    StopLoss       = 0;
extern int    TakeProfit     = 12;
extern double Lots           = 0.01;
extern int    magicnumber    = 777;
extern int    MaxOrders      = 1;
extern int    Periods        = 1;
extern int    Periods2       = 5;

int prevtime;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----





   int i=0;  
   int total = OrdersTotal();   
   int balance=AccountBalance()/500;
   double lot=balance*0.1;

   for(i = 0; i <= total; i++) 
     {
      if(TrailingStop>0)  
       {                 
       OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
}
      }

 double M_0, M_1,               // Çíà÷åíèå MAIN íà 0 è 1 áàðàõ
        S_0, S_1,               // Çíà÷åíèå SIGNAL íà 0 è 1áàðàõ
        M_0a,M_1a,
        S_0a,S_1a;
bool BuyOp=false;
bool BuySell=false;

//--------------------------------------------------------------------
                                  // Îáðàùåíèå ê ôóíêöèè òåõí.èíäèêàò.
   M_0 = iStochastic(NULL,Periods,5,3,3,MODE_SMA,0,MODE_MAIN,  0);// 0 áàð
   M_1 = iStochastic(NULL,Periods,5,3,3,MODE_SMA,0,MODE_MAIN,  1);// 1 áàð
   S_0 = iStochastic(NULL,Periods,5,3,3,MODE_SMA,0,MODE_SIGNAL,0);// 0 áàð
   S_1 = iStochastic(NULL,Periods,5,3,3,MODE_SMA,0,MODE_SIGNAL,1);// 1 áàð
   M_0a = iStochastic(NULL,Periods2,5,3,3,MODE_SMA,0,MODE_MAIN,  0);// 0 áàð
   M_1a = iStochastic(NULL,Periods2,5,3,3,MODE_SMA,0,MODE_MAIN,  1);// 1 áàð
   S_0a = iStochastic(NULL,Periods2,5,3,3,MODE_SMA,0,MODE_SIGNAL,0);// 0 áàð
   S_1a = iStochastic(NULL,Periods2,5,3,3,MODE_SMA,0,MODE_SIGNAL,1);// 1 áàð

//--------------------------------------------------------------------

if (High[0]<High[1]&&High[1]<High[2]&&High[2]<High[3]&&Open[0]<Open[1]&&Open[1]<Open[2]&&Open[2]<Open[3]) { 
   BuyOp=true;
   Print("Drei Long-Kerzen hintereinander!");}
if (High[0]>High[1]&&High[1]>High[2]&&High[2]>High[3]&&Open[0]>Open[1]&&Open[1]>Open[2]&&Open[2]>Open[3]) {
   BuySell=true;
   Print("Drei Short-Kerzen hintereinander!");}

   if(Time[0] == prevtime) 
       return(0);
   prevtime = Time[0];
   if(!IsTradeAllowed()) 
     {
       prevtime = Time[1];
       return(0);
     }


//----
    if (total < MaxOrders || MaxOrders == 0)
     {   
       if(BuyOp)
        { 
          if( M_1 > S_1 && M_0 > S_0 )   // Çåë¸íàÿ âûøå êðàñíîé
          {
                   if( M_1a > S_1a && M_0a > S_0a )   // Çåë¸íàÿ âûøå êðàñíîé
            {
           OrderSend(Symbol(),OP_BUY,lot,Ask,3,Bid-(StopLoss*Point),Ask+(TakeProfit*Point),"OpenTiks_Buy",magicnumber,0,Green);
          }
        }
        }
        if(BuySell)
        { 
          if( M_1 > S_1 && M_0 > S_0 )   // Çåë¸íàÿ âûøå êðàñíîé
          {
                   if( M_1a < S_1a && M_0a < S_0a )   // Çåë¸íàÿ âûøå êðàñíîé
            {
           OrderSend(Symbol(),OP_SELL,lot,Ask,3,Bid+(StopLoss*Point),Ask-(TakeProfit*Point),"OpenTiks_Sell",magicnumber,0,Red);
          }
        }
        }
        }
  
   
//----
   return(0);
  } 
//+------------------------------------------------------------------+

