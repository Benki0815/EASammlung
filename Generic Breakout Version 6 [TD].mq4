//+------------------------------------------------------------------+
#define SIGNAL_NONE 0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2
#define SIGNAL_CLOSEBUY 3
#define SIGNAL_CLOSESELL 4

#property copyright "Ronald Raygun"
#property link      "http://www.RonaldRaygunForex.com/Support/"


#import "wininet.dll"

#define INTERNET_FLAG_PRAGMA_NOCACHE    0x00000100 // Forces the request to be resolved by the origin server, even if a cached copy exists on the proxy.
#define INTERNET_FLAG_NO_CACHE_WRITE    0x04000000 // Does not add the returned entity to the cache. 
#define INTERNET_FLAG_RELOAD            0x80000000 // Forces a download of the requested file, object, or directory listing from the origin server, not from the cache.
#define INTERNET_FLAG_NO_COOKIES        0x00080000 // Does not automatically add cookie headers to requests, and does not automatically add returned cookies to the cookie database. This flag can be used by 


int InternetOpenA(
	string 	sAgent,
	int		lAccessType,
	string 	sProxyName="",
	string 	sProxyBypass="",
	int 	lFlags=0
);

int InternetOpenUrlA(
	int 	hInternetSession,
	string 	sUrl, 
	string 	sHeaders="",
	int 	lHeadersLength=0,
	int 	lFlags=0,
	int 	lContext=0 
);

int InternetReadFile(
	int 	hFile,
	string 	sBuffer,
	int 	lNumBytesToRead,
	int& 	lNumberOfBytesRead[]
);

int InternetCloseHandle(
	int 	hInet
);
#import


extern string Remark1 = "== Main Settings ==";
extern int MagicNumber = 0;
extern bool SignalsOnly = False;
extern bool Alerts = False;
extern bool SignalMail = False;
extern bool PlaySounds = False;
extern bool ECNBroker = False;
extern bool TickDatabase = True;
extern bool UseTradingTimes = True;
extern int TradeStartHour = 0;
extern int TradeStartMinute = 0;
extern int TradeStopHour = 0;
extern int TradeStopMinute = 0;
extern bool EachTickMode = True;
extern double Lots = 0;
extern bool MoneyManagement = False;
extern int Risk = 0;
extern int Slippage = 5;
extern  bool UseStopLoss = True;
extern bool UseFixedStopLoss = True;
extern int StopLoss = 100;
extern bool UseSLRangeMultiplier = True;
extern double SLRangeMultiplier = 1;
extern bool UseTakeProfit = False;
extern bool UseFixedTakeProfit = True;
extern int TakeProfit = 60;
extern bool UseTPRangeMultiplier = True;
extern double TPRangeMultiplier = 1;
extern bool UseTrailingStop = False;
extern int TrailingStop = 30;
extern bool UseTrailByRange = True;
extern double RangeMultiplier = 1;
extern bool MoveStopOnce = False;
extern int MoveStopWhenPrice = 50;
extern int MoveStopTo = 1;
extern string Remark2 = "";
extern string Remark3 = "== Breakout Settings ==";
extern int StartHour = 0;
extern int StartMinute = 0;
extern int EndHour = 0;
extern int EndMinute = 0;
extern int BreakoutBuffer = 0;
extern bool UseMaxRange = False;
extern int MaxRange = 0;
extern int MaxTotalTrades = 0;
extern int MaxLongTrades = 0;
extern int MaxShortTrades = 0;
extern int MaxProfitTrades = 0;
extern int MaxLossTrades = 0;


string SymbolUsed;
int TickCount = 0;
int RecordDay = -1;
string UserName = "";
bool ShowDiagnostics = False;

int Internet_Open_Type_Direct = 1;


   string URL;
   int URLHandle = 0;                                                              
   int SessionHandle = 0;
   int MaxTries = 0;

   
   string FinalStr ;
   int bytesreturned[1];
   int readresult;

   int GMTBar;
   string GMTTime;
   string BrokerTime;
   int GMTShift;

   datetime CurGMTTime;
   datetime CurBrokerTime;
   datetime CurrentGMTTime;



 
   string TempStr ="000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
#define  maxreadlen 200

int LongTrades;
int ShortTrades;
int TotalTrades;

datetime ResetCheck;

int TradeBar;
int TradesThisBar;

int OpenBarCount;
int CloseBarCount;

string BrokerType = "4-Digit Broker";
double BrokerMultiplier = 1;

int Current;
bool TickCheck = False;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {


         
      
   OpenBarCount = Bars;
   CloseBarCount = Bars;
   
   TickCount = 0;
   
   SymbolUsed = StringSubstr(Symbol(), 0, 6);   
   RecordDay = TimeDayOfYear(TimeCurrent());
   
   

   
   if(Digits == 3 || Digits == 5)
      {
      BrokerType = "5-Digit Broker";
      BrokerMultiplier = 10;
      }


   if (EachTickMode) Current = 0; else Current = 1;

   return(0);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit() {

   URL = LoadURL("http://www.ronaldraygunforex.com/TickDB/UserLog.php?UN="+UserName+"&P="+SymbolUsed+"&TL="+TickCount);
   if(TickDatabase && !IsTesting() && !IsOptimization()) Print("Thank you for contributing "+TickCount+" ticks. "/*+URL*/);
   InternetCloseHandle(SessionHandle);
   
   
ObjectDelete("HighValue");
ObjectDelete("LowValue");
ObjectDelete("LongEntry");
ObjectDelete("ShortEntry");
ObjectDelete("RangeStart");
ObjectDelete("RangeEnd");


   return(0);
}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start() 


{
   if(!IsDllsAllowed() && TickDatabase)
      {
      Alert("ERROR: Please enable DLL calls.");
      Comment("Enable DLL Calls");
      return(0);
      }  

   if(StartHour > 23 || StartHour < 0) 
      {
      Alert("Error: Your StartHour parameter is outside the acceptable range.");
      return(0);
      }
   
   if(StartMinute > 59 || StartMinute < 0) 
      {
      Alert("Error: Your StartMinute parameter is outside the acceptable range.");
      return(0);
      }      
   
   if(EndHour > 23 || EndHour < 0) 
      {
      Alert("Error: Your EndHour parameter is outside the acceptable range.");
      return(0);
      }   
   
   if(EndMinute > 59 || EndMinute < 0) 
      {
      Alert("Error: Your EndMinute parameter is outside the acceptable range.");
      return(0);
      }   

   if(TradeStartHour > 23 || TradeStartHour < 0)
      {
      Alert("Error: Your TradeStartHour parameter is outside the acceptable range.");
      return(0);
      }   
      
   if(TradeStartMinute > 59 || TradeStartMinute < 0) 
      {
      Alert("Error: Your TradeStartMinute parameter is outside the acceptable range.");
      return(0);
      }
      
   if(TradeStopHour > 23 || TradeStopHour < 0)
      {
      Alert("Error: Your TradeStopHour parameter is outside the acceptable range.");
      return(0);
      }   
      
   if(TradeStopMinute > 59 || TradeStopMinute < 0)
      {
      Alert("Error: Your TradeStopMinute parameter is outside the acceptable range.");
      return(0);
      }

   int Order = SIGNAL_NONE;
   int Total, Ticket;
   double StopLossLevel, TakeProfitLevel;
   double PotentialStopLoss;
   double BEven; 
   double TrailStop;
   double RangeStop;
   double FixedStopLoss;
   double RangeStopLoss;
   double FixedTakeProfit;
   double RangeTakeProfit;



   if (EachTickMode && Bars != CloseBarCount) TickCheck = False;
   Total = OrdersTotal();
   Order = SIGNAL_NONE;

//Limit Trades Per Bar
if(TradeBar != Bars)
   {
   TradeBar = Bars;
   TradesThisBar = 0;
   }


//Money Management sequence
 if (MoneyManagement)
   {
      if (Risk<1 || Risk>100)
      {
         Comment("Invalid Risk Value.");
         return(0);
      }
      else
      {
         Lots=MathFloor((AccountFreeMargin()*AccountLeverage()*Risk*Point*BrokerMultiplier*100)/(Ask*MarketInfo(Symbol(),MODE_LOTSIZE)*MarketInfo(Symbol(),MODE_MINLOT)))*MarketInfo(Symbol(),MODE_MINLOT);
      }
   }

   //+------------------------------------------------------------------+
   //| Variable Begin                                                   |
   //+------------------------------------------------------------------+
   
string TradingTimes = "Outside Trading Times";
datetime TradingStart = StrToTime(TradeStartHour+":"+TradeStartMinute);
datetime TradingStop = StrToTime(TradeStopHour+":"+TradeStopMinute);
if(TradingStart < TradingStop && TimeCurrent() >= TradingStart && TimeCurrent() < TradingStop) TradingTimes = "Inside Trading Times";
if(TradingStart > TradingStop && (TimeCurrent() >= TradingStart || TimeCurrent() < TradingStop)) TradingTimes = "Inside Trading Times";
if(!UseTradingTimes) TradingTimes = "Not Used";   

datetime RangeStart = StrToTime(StartHour+":"+StartMinute);
datetime RangeEnd = StrToTime(EndHour+":"+EndMinute);

if(RangeStart > RangeEnd) RangeStart = RangeStart - 86400;

int StartShift = iBarShift(NULL, 0, RangeStart, False);
int EndShift = iBarShift(NULL, 0, RangeEnd, False);

double RangeHigh = iHigh(NULL, 0, iHighest(NULL, 0, PRICE_HIGH, StartShift - EndShift, EndShift));
double RangeLow = iLow(NULL, 0, iLowest(NULL, 0, PRICE_LOW, StartShift - EndShift, EndShift));

double LongEntry = RangeHigh + (BreakoutBuffer * Point);
double ShortEntry = RangeLow - (BreakoutBuffer * Point);

if(ResetCheck < RangeEnd)
   {
   ResetCheck = RangeEnd;
   LongTrades = 0;
   ShortTrades = 0;
   TotalTrades = 0;
   }

int ProfitTrade = 0;
int LossTrade = 0;
int TotalOrders = OrdersHistoryTotal();
Print("TotalOrder: ", TotalOrders);
for(int H = TotalOrders; H > 0; H--)
   {
   OrderSelect(H, SELECT_BY_POS, MODE_HISTORY);
   if((OrderType() == OP_BUY || OrderType() == OP_SELL) && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol() && OrderOpenTime() >= RangeEnd)
      {
      if(OrderProfit() > 0) ProfitTrade++;          
      if(OrderProfit() < 0) LossTrade++;        
      }
   }

double Range = (RangeHigh - RangeLow) / Point;


string TradeTrigger = "None";
if((Range < MaxRange || !UseMaxRange) && TradingTimes != "Outside Trading Times" && (LossTrade < MaxLossTrades || MaxLossTrades == 0) && (ProfitTrade < MaxProfitTrades || MaxProfitTrades == 0) && (MaxLongTrades > LongTrades || MaxLongTrades == 0) && (MaxTotalTrades > TotalTrades || MaxTotalTrades == 0) && iLow(NULL, 0, Current + 0) < LongEntry && iClose(NULL, 0, Current + 0) >= LongEntry) TradeTrigger = "Open Long";
if((Range < MaxRange || !UseMaxRange) && TradingTimes != "Outside Trading Times" && (LossTrade < MaxLossTrades || MaxLossTrades == 0) && (ProfitTrade < MaxProfitTrades || MaxProfitTrades == 0) && (MaxShortTrades > ShortTrades || MaxShortTrades == 0) && (MaxTotalTrades > TotalTrades || MaxTotalTrades == 0) && iHigh(NULL, 0, Current + 0) > ShortEntry && iClose(NULL, 0, Current + 0) <= ShortEntry) TradeTrigger = "Open Short";

Comment("Broker Type: ", BrokerType, "\n",
        "Trading Times: ", TradingTimes, "\n",
        "Range Start: ", TimeToStr(RangeStart, TIME_DATE|TIME_SECONDS), "\n",
        "Range End: ", TimeToStr(RangeEnd, TIME_DATE|TIME_SECONDS), "\n",
        "Long Entry: ", LongEntry, "\n",
        "Short Entry: ", ShortEntry, "\n",
        "Today\'s Profit Trades: ", ProfitTrade, "\n",
        "Today\'s Loss Trades: ", LossTrade, "\n",
        "Today\'s Long Trades: ", LongTrades, "\n",
        "Today\'s Short Trades: ", ShortTrades, "\n",
        "Today\'s Total Trades: ", TotalTrades, "\n",
        "Trade Trigger: ", TradeTrigger);

ObjectDelete("HighValue");
ObjectCreate("HighValue", OBJ_HLINE, 0, 0, RangeHigh);
ObjectSet("HighValue", OBJPROP_COLOR, Yellow);
ObjectSet("HighValue", OBJPROP_STYLE, STYLE_DOT);
ObjectSet("HighValue", OBJPROP_BACK, True);

ObjectDelete("LowValue");
ObjectCreate("LowValue", OBJ_HLINE, 0, 0, RangeLow);
ObjectSet("LowValue", OBJPROP_COLOR, Yellow);
ObjectSet("LowValue", OBJPROP_STYLE, STYLE_DOT);
ObjectSet("LowValue", OBJPROP_BACK, True);

ObjectDelete("LongEntry");
ObjectCreate("LongEntry", OBJ_HLINE, 0, 0, LongEntry);
ObjectSet("LongEntry", OBJPROP_COLOR, Lime);
ObjectSet("LongEntry", OBJPROP_STYLE, STYLE_DOT);
ObjectSet("LongEntry", OBJPROP_BACK, True);

ObjectDelete("ShortEntry");
ObjectCreate("ShortEntry", OBJ_HLINE, 0, 0, ShortEntry);
ObjectSet("ShortEntry", OBJPROP_COLOR, Red);
ObjectSet("ShortEntry", OBJPROP_STYLE, STYLE_DOT);
ObjectSet("ShortEntry", OBJPROP_BACK, True);

ObjectDelete("RangeStart");
ObjectCreate("RangeStart", OBJ_VLINE, 0, RangeStart, 0);
ObjectSet("RangeStart", OBJPROP_COLOR, Yellow);
ObjectSet("RangeStart", OBJPROP_STYLE, STYLE_SOLID);
ObjectSet("RangeStart", OBJPROP_BACK, True);

ObjectDelete("RangeEnd");
ObjectCreate("RangeEnd", OBJ_VLINE, 0, RangeEnd, 0);
ObjectSet("RangeEnd", OBJPROP_COLOR, Yellow);
ObjectSet("RangeEnd", OBJPROP_STYLE, STYLE_SOLID);
ObjectSet("RangeEnd", OBJPROP_BACK, True);


   //+------------------------------------------------------------------+
   //| Variable End                                                     |
   //+------------------------------------------------------------------+

   //Check position
   bool IsTrade = False;

   for (int i = 0; i < Total; i ++) {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if(OrderType() <= OP_SELL &&  OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
         IsTrade = True;
         if(OrderType() == OP_BUY) {
         
            
            //Close

            //+------------------------------------------------------------------+
            //| Signal Begin(Exit Buy)                                           |
            //+------------------------------------------------------------------+



            //+------------------------------------------------------------------+
            //| Signal End(Exit Buy)                                             |
            //+------------------------------------------------------------------+

            if (Order == SIGNAL_CLOSEBUY && ((EachTickMode && !TickCheck) || (!EachTickMode && (Bars != CloseBarCount)))) {
               OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, MediumSeaGreen);
               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Bid, Digits) + " Close Buy");
               if (!EachTickMode) CloseBarCount = Bars;
               IsTrade = False;
               continue;
            }
            
            PotentialStopLoss = OrderStopLoss();
            BEven = BreakEvenValue(MoveStopOnce, OrderTicket(), MoveStopTo, MoveStopWhenPrice);
            TrailStop = TrailingStopValue(UseTrailingStop, OrderTicket(), TrailingStop);
            RangeStop = TrailingStopValue(UseTrailByRange, OrderTicket(), (RangeMultiplier * Range));
            
            if(BEven > PotentialStopLoss && BEven != 0) PotentialStopLoss = BEven;
            if(TrailStop > PotentialStopLoss && TrailStop != 0) PotentialStopLoss = TrailStop;
            if(RangeStop > PotentialStopLoss && RangeStop != 0) PotentialStopLoss = RangeStop;
             
            if(PotentialStopLoss != OrderStopLoss()) OrderModify(OrderTicket(),OrderOpenPrice(), PotentialStopLoss, OrderTakeProfit(), 0, MediumSeaGreen); 
         
         } else {
        
            //Close

            //+------------------------------------------------------------------+
            //| Signal Begin(Exit Sell)                                          |
            //+------------------------------------------------------------------+



            //+------------------------------------------------------------------+
            //| Signal End(Exit Sell)                                            |
            //+------------------------------------------------------------------+

            if (Order == SIGNAL_CLOSESELL && ((EachTickMode && !TickCheck) || (!EachTickMode && (Bars != CloseBarCount)))) {
               OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, DarkOrange);
               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + " Close Sell");
               if (!EachTickMode) CloseBarCount = Bars;
               IsTrade = False;
               continue;
            }
            
            PotentialStopLoss = OrderStopLoss();
            BEven = BreakEvenValue(MoveStopOnce, OrderTicket(), MoveStopTo, MoveStopWhenPrice);
            TrailStop = TrailingStopValue(UseTrailingStop, OrderTicket(), TrailingStop);
            RangeStop = TrailingStopValue(UseTrailByRange, OrderTicket(), (RangeMultiplier * Range));
            
            if((BEven < PotentialStopLoss && BEven != 0) || (PotentialStopLoss == 0)) PotentialStopLoss = BEven;
            if((TrailStop < PotentialStopLoss && TrailStop != 0) || (PotentialStopLoss == 0)) PotentialStopLoss = TrailStop;
            if((RangeStop < PotentialStopLoss && RangeStop != 0) || (PotentialStopLoss == 0)) PotentialStopLoss = RangeStop;
            
            if(PotentialStopLoss != OrderStopLoss() || OrderStopLoss() == 0) OrderModify(OrderTicket(),OrderOpenPrice(), PotentialStopLoss, OrderTakeProfit(), 0, DarkOrange);
              
         }
      }
   }

   //+------------------------------------------------------------------+
   //| Signal Begin(Entry)                                              |
   //+------------------------------------------------------------------+

if(TradeTrigger == "Open Long") Order = SIGNAL_BUY;
if(TradeTrigger == "Open Short") Order = SIGNAL_SELL;

   //+------------------------------------------------------------------+
   //| Signal End                                                       |
   //+------------------------------------------------------------------+

   //Buy
   if (Order == SIGNAL_BUY && ((EachTickMode && !TickCheck) || (!EachTickMode && (Bars != OpenBarCount)))) {
      if(SignalsOnly) {
         if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + "Buy Signal");
         if (Alerts) Alert("[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + "Buy Signal");
         if (PlaySounds) PlaySound("alert.wav");
     
      }
      
      if(!IsTrade && !SignalsOnly && TradesThisBar < 1) {
         //Check free margin
         if (AccountFreeMarginCheck(Symbol(), OP_BUY, Lots) < 0) {
            Print("We have no money. Free Margin = ", AccountFreeMargin());
            return(0);
         }

         FixedStopLoss = Ask - StopLoss * Point; 
         RangeStopLoss = Ask - (Range * SLRangeMultiplier);
         if (UseStopLoss && UseFixedStopLoss && FixedStopLoss != 0 && (FixedStopLoss > StopLossLevel || StopLossLevel == 0)) StopLossLevel = FixedStopLoss;
         if (UseStopLoss && UseSLRangeMultiplier && RangeStopLoss != 0 && (RangeStopLoss > StopLossLevel || StopLossLevel == 0)) StopLossLevel = RangeStopLoss;
         if (!UseStopLoss) StopLossLevel = 0.0;
         
         FixedTakeProfit = Ask + TakeProfit * Point; 
         RangeTakeProfit = Ask + (Range * TPRangeMultiplier);
         if (UseTakeProfit && UseFixedTakeProfit && FixedTakeProfit != 0 && (FixedTakeProfit > TakeProfitLevel || TakeProfitLevel == 0)) TakeProfitLevel = FixedTakeProfit;
         if (UseTakeProfit && UseTPRangeMultiplier && RangeTakeProfit != 0 && (RangeTakeProfit > TakeProfitLevel || TakeProfitLevel == 0)) TakeProfitLevel = RangeTakeProfit;
         if (!UseTakeProfit) TakeProfitLevel = 0.0;
         
         if(ECNBroker) Ticket = OrderModify(OrderSend(Symbol(), OP_BUY, Lots, Ask, Slippage, 0, 0, "Buy(#" + MagicNumber + ")", MagicNumber, 0, DodgerBlue), OrderOpenPrice(), StopLossLevel, TakeProfitLevel, 0, CLR_NONE);
         if(!ECNBroker) Ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, Slippage, StopLossLevel, TakeProfitLevel, "Buy(#" + MagicNumber + ")", MagicNumber, 0, DodgerBlue);
            if(Ticket > 0) {
               if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
				  Print("BUY order opened : ", OrderOpenPrice());
                  if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + "Buy Signal");
			         if (Alerts) Alert("[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + "Buy Signal");
                  if (PlaySounds) PlaySound("alert.wav");
                  TradesThisBar++;
                  LongTrades++;
                  TotalTrades++;
			   } else {
   				Print("Error opening BUY order : ", GetLastError());
			   }
            }
            
         if (EachTickMode) TickCheck = True;
         if (!EachTickMode) OpenBarCount = Bars;
         return(0);
      }
   }

   //Sell
   if (Order == SIGNAL_SELL && ((EachTickMode && !TickCheck) || (!EachTickMode && (Bars != OpenBarCount)))) {
      if(SignalsOnly) {
          if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Bid, Digits) + "Sell Signal");
          if (Alerts) Alert("[" + Symbol() + "] " + DoubleToStr(Bid, Digits) + "Sell Signal");
          if (PlaySounds) PlaySound("alert.wav");
         }
      if(!IsTrade && !SignalsOnly && TradesThisBar < 1) {
         //Check free margin
         if (AccountFreeMarginCheck(Symbol(), OP_SELL, Lots) < 0) {
            Print("We have no money. Free Margin = ", AccountFreeMargin());
            return(0);
         }

         FixedStopLoss = Bid + StopLoss * Point; 
         RangeStopLoss = Bid + (Range * SLRangeMultiplier);
         if (UseStopLoss && UseFixedStopLoss && FixedStopLoss != 0 && (FixedStopLoss < StopLossLevel || StopLossLevel == 0)) StopLossLevel = FixedStopLoss;
         if (UseStopLoss && UseSLRangeMultiplier && RangeStopLoss != 0 && (RangeStopLoss < StopLossLevel || StopLossLevel == 0)) StopLossLevel = RangeStopLoss;
         if (!UseStopLoss) StopLossLevel = 0.0;
         
         FixedTakeProfit = Bid - TakeProfit * Point; 
         RangeTakeProfit = Bid - (Range * TPRangeMultiplier);
         if (UseTakeProfit && UseFixedTakeProfit && FixedTakeProfit != 0 && (FixedTakeProfit < TakeProfitLevel || TakeProfitLevel == 0)) TakeProfitLevel = FixedTakeProfit;
         if (UseTakeProfit && UseTPRangeMultiplier && RangeTakeProfit != 0 && (RangeTakeProfit < TakeProfitLevel || TakeProfitLevel == 0)) TakeProfitLevel = RangeTakeProfit;
         if (!UseTakeProfit) TakeProfitLevel = 0.0;

         if(ECNBroker) Ticket = OrderModify(OrderSend(Symbol(), OP_SELL, Lots, Bid, Slippage, 0, 0, "Sell(#" + MagicNumber + ")", MagicNumber, 0, DeepPink), OrderOpenPrice(), StopLossLevel, TakeProfitLevel, 0, CLR_NONE);
         if(!ECNBroker) Ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, Slippage, StopLossLevel, TakeProfitLevel, "Sell(#" + MagicNumber + ")", MagicNumber, 0, DeepPink);
         if(Ticket > 0) {
            if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
				Print("SELL order opened : ", OrderOpenPrice());
                if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Bid, Digits) + "Sell Signal");
			       if (Alerts) Alert("[" + Symbol() + "] " + DoubleToStr(Bid, Digits) + "Sell Signal");
                if (PlaySounds) PlaySound("alert.wav");
                TradesThisBar++;
                ShortTrades++;
                TotalTrades++;
			} else {
				Print("Error opening SELL order : ", GetLastError());
			}
         }
         if (EachTickMode) TickCheck = True;
         if (!EachTickMode) OpenBarCount = Bars;
         return(0);
      }
   }

   if (!EachTickMode) CloseBarCount = Bars;

   
   if(!IsOptimization() && !IsTesting() && IsDllsAllowed() && TickDatabase) TickData();
   
   return(0);
}

void TickData ()
   {
   if(GMTBar != Bars)
      {
      GMTTime = LoadURL("http://www.ronaldraygunforex.com/TickDB/Time.php");
      GMTBar = Bars;
      GMTShift = TimeCurrent() - StrToTime(GMTTime);
      } 

   if(TimeDayOfYear(TimeCurrent()) != RecordDay)
      {
      URL = LoadURL("http://www.ronaldraygunforex.com/TickDB/UserLog.php?UN="+UserName+"&P="+SymbolUsed+"&TL="+TickCount);
   
      if(StringFind(URL, "1 record added") != -1)
         {
         TickCount = 0;
         RecordDay = TimeDayOfYear(TimeCurrent());
         }
      }
   
   CurGMTTime = StrToTime(GMTTime);
  
   CurrentGMTTime = TimeCurrent() - GMTShift;
   //CurrentGMTTime = CurGMTTime + TimeCurrent - CurBrokerTime
   
   URL = LoadURL("http://www.ronaldraygunforex.com/TickDB/Load.php?TN="+SymbolUsed+"&GMT="+CurrentGMTTime+"&TT="+TimeCurrent()+"&B="+DoubleToStr(NormalizeDouble(Bid,Digits),Digits)+"&A="+DoubleToStr(NormalizeDouble(Ask,Digits),Digits)+"&BN="+AccountCompany()+"&UN="+UserName);
  
   if(StringFind(URL, "1 record added") != -1)
      {
      TickCount++;
      }
      else
      {
      Print(SymbolUsed+" Error: "+URL);
      LoadURL("http://www.ronaldraygunforex.com/TickDB/Error.php?UN="+UserName+"&Error="+URL);
      }
   }
   
   
string LoadURL (string URLLoad)
   {
   int Position = StringFind(URLLoad, " ");
   
   while (Position != -1)
      {
      string InitialURLA = StringTrimLeft(StringTrimRight(StringSubstr(URLLoad, 0, StringFind(URLLoad, " ", 0))));
      string InitialURLB = StringTrimLeft(StringTrimRight(StringSubstr(URLLoad, StringFind(URLLoad, " ", 0))));
      URLLoad = InitialURLA+"%20"+InitialURLB;
      Position = StringFind(URLLoad, " ");
      if(ShowDiagnostics) Print("Processing URL: "+URLLoad);
      }
      
   MaxTries =0; 
   URLHandle=0;
   while (MaxTries < 3 && URLHandle == 0)
      {
      if(SessionHandle != 0)
         {
         URLHandle = InternetOpenUrlA(SessionHandle, URLLoad, NULL, 0, INTERNET_FLAG_NO_CACHE_WRITE |
                                                                   INTERNET_FLAG_PRAGMA_NOCACHE |
                                                                   INTERNET_FLAG_RELOAD |
                                                                   INTERNET_FLAG_NO_COOKIES, 0);
         }
      if(URLHandle == 0)
         {
         InternetCloseHandle(SessionHandle);
         if(ShowDiagnostics) Print("Closing Handle");
         SessionHandle = InternetOpenA("mymt4InetSession", Internet_Open_Type_Direct, NULL, NULL, 0);
         }
         
      MaxTries++;   
      }
      
   if(ShowDiagnostics) Print("URL Handle: ", URLHandle);   
      
   //Parse file 
    
   FinalStr = "";
   bytesreturned[0]=1;
   
   while (bytesreturned[0] > 0)
      {

    
     
      // get next chunk
      InternetReadFile(URLHandle, TempStr , maxreadlen, bytesreturned);
      if(ShowDiagnostics) Print("bytes returned: "+bytesreturned[0]);
      
      

      if(bytesreturned[0] > 0)
      FinalStr = FinalStr + StringSubstr(TempStr, 0, bytesreturned[0]);
            
      }

      if(ShowDiagnostics) Print("FinalStr: "+FinalStr);

   // now we are done with the URL we can close its handle 
   InternetCloseHandle(URLHandle);
   
   return(FinalStr);    
   }

double BreakEvenValue (bool Decision, int OrderTicketNum, int MoveStopTo, int MoveStopwhenPrice)
   {
   //Select the appropriate order ticket
   OrderSelect(OrderTicketNum, SELECT_BY_TICKET, MODE_TRADES);
   
   //If the Order is a BUY order...
   if(OrderType() == OP_BUY)
      {
      //Check if the user wants to use the MoveStopOnce function and did it correctly
      if(Decision && MoveStopWhenPrice > 0) 
         {
         //Check if the trade is above the required profit threshold
         if(Bid - OrderOpenPrice() >= Point * MoveStopWhenPrice) 
            {
            //Return the value of the stoploss
            return(OrderOpenPrice() + Point * MoveStopTo);
            }
         }
      }
   
   //If the Order is a SELL order...   
   if(OrderType() == OP_SELL)
      {
      //Check if the user wants to use the MoveStopOnce function and did it correctly
      if(Decision && MoveStopWhenPrice > 0) 
         {
         //Check if the trade is above the required profit threshold
         if(OrderOpenPrice() - Ask >= Point * MoveStopWhenPrice) 
            {
            //Return the value of the stoploss
            return(OrderOpenPrice() - Point * MoveStopTo);
            }
         }
      }   
      
   if(OrderType() != OP_BUY || OrderType() != OP_SELL) return(0);
   }
   
double TrailingStopValue (bool Decision, int OrderTicketNum, int TrailingStop)
   {
   //Select the appropriate order ticket
   OrderSelect(OrderTicketNum, SELECT_BY_TICKET, MODE_TRADES);
   
   //If the Order is a BUY order...
   if(OrderType() == OP_BUY)
      {
      //Check if the user wants to use teh Trailingstop function and did it correctly
      if(Decision && TrailingStop > 0) 
         {                 
         //Check to see that the profit threshold is met
         if(Bid - OrderOpenPrice() > Point * TrailingStop) 
            {
            //Return the value of the potential stoploss
            return(Bid - Point * TrailingStop);
            }
         }
      }
   //If the Order is a SELL order...
   if(OrderType() == OP_SELL)
      {
      //Check if the user wants to use teh Trailingstop function and did it correctly
      if(Decision && TrailingStop > 0) 
         {                 
         //Check to see that the profit threshold is met
         if((OrderOpenPrice() - Ask) > (Point * TrailingStop)) 
            {
            //Return the value of the potential stoploss
            return(Ask + Point * TrailingStop);
            }
         }
      }     
   //If the trade is not the right order type, give a stoploss of 0   
   if(OrderType() != OP_BUY || OrderType() != OP_SELL) return(0);
   }