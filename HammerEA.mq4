//+------------------------------------------------------------------+
//|                                                    Hammer EA.mq4 |
//|                              Copyright © 2008, TradingSytemForex |
//|                                http://www.tradingsystemforex.com |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2008, TradingSytemForex"
#property link "http://www.tradingsystemforex.com"

#define OrSt "Hammer EA"

extern string SET="---------------- Settings";
extern int XpipsOverUnder=15;
extern int KeepStopOrderForXMin=240;
extern int MAPeriod1=20;
extern int MAMethod1=1;
extern int MAPrice1=0;
extern string LM="---------------- Lot Management";
extern double Lots=0.1;
extern bool MM=false; //money management
extern double Risk=10; //risk in percentage
extern bool Martingale=false; //martingale
extern double Multiplier=1.5; //multiplier
extern double MinProfit=0; //minimum profit to apply the martingale
extern string TSTB="---------------- TP SL TS BE";
bool EnableRealSL=false;
int RealSL=5; //stop loss under 15 pîps
bool EnableRealTP=false;
int RealTP=10; //take profit under 10 pîps
extern int SL=0; //stop loss
extern int TP=0; //take profit
extern int TS=0; //trailing stop
int TSStep=1; //trailing step
extern int BE=0; //breakeven
extern string EXT="---------------- Extras";
extern bool Reverse=false;
extern bool AddPositions=true; //positions cumulated
extern int MaxOrders=5; //maximum number of orders
extern bool MAFilter=false; //moving average filter
extern int MAPeriod=20;
extern int MAMethod=1;
extern int MAPrice=0;
extern bool TimeFilter=false; //time filter
extern int StartHour=8;
extern int EndHour=21;
extern int Magic=0;
int MaxTradePerBar=1;

datetime Time0;int TradePerBar=0;int BarCount=-1;

int Slip=3;static int TL=0;double Balance=0.0;int err=0;int TK;

int init(){Time0=Time[0];return(0);}
int deinit(){return(0);}

// expert start function
int start(){int j=0,limit=1;double BV=0,SV=0;BV=0;SV=0;double MAC1,MAC2,MAC3;
if(CntO(OP_BUYSTOP,Magic)>0)TL=1;if(CntO(OP_SELLSTOP,Magic)>0)TL=-1;for(int i=1;i<=limit;i++){

string TIFI="false";
if(TimeFilter){if(!(Hour()>=StartHour && Hour()<=EndHour)){TIFI="true";}}

double MAF=iMA(Symbol(),0,MAPeriod,0,MAMethod,MAPrice,i); 
string MAFIB="false";string MAFIS="false";
if(MAFilter){if(Bid>MAF)MAFIB="true";if(Ask<MAF)MAFIS="true";}
  
double MA=iMA(Symbol(),0,MAPeriod1,0,MAMethod1,MAPrice1,i); 
string SBUY="false";string SSEL="false";
if((Close[i]>Open[i]&&(Close[i]-Open[i])>(High[i]-Close[i])&&(Open[i]-Low[i])>2*(Close[i]-Open[i])&&Low[i]>MA)||
(Open[i]>Close[i]&&(Open[i]-Close[i])>(High[i]-Open[i])&&(Close[i]-Low[i])>2*(Open[i]-Close[i])&&Low[i]>MA))SBUY="true";
if((Close[i]>Open[i]&&(Close[i]-Open[i])>(High[i]-Close[i])&&(Open[i]-Low[i])>2*(Close[i]-Open[i])&&High[i]<MA)||
(Open[i]>Close[i]&&(Open[i]-Close[i])>(High[i]-Open[i])&&(Close[i]-Low[i])>2*(Open[i]-Close[i])&&High[i]<MA))SSEL="true";

if(((MAFilter==false)||(MAFilter&&MAFIB=="true"))&&SBUY=="true"&&TIFI=="false"&&(TradePerBar<=MaxTradePerBar)){if(Reverse)SV=1;else BV=1;break;}
if(((MAFilter==false)||(MAFilter&&MAFIS=="true"))&&SSEL=="true"&&TIFI=="false"&&(TradePerBar<=MaxTradePerBar)){if(Reverse)BV=1;else SV=1;break;}}

if(BarCount!=Bars){TradePerBar=0;BarCount=Bars;}
            
int expire=0;
if(KeepStopOrderForXMin>0)expire=TimeCurrent()+(KeepStopOrderForXMin*60)-5;

// expert money management
if(MM){if(Risk<0.1||Risk>100){Comment("Invalid Risk Value.");return(0);}
else{Lots=MathFloor((AccountFreeMargin()*AccountLeverage()*Risk*Point*100)/(Ask*MarketInfo(Symbol(),MODE_LOTSIZE)*MarketInfo(Symbol(),MODE_MINLOT)))*MarketInfo(Symbol(),MODE_MINLOT);}}
if(MM==false){Lots=Lots;}
if(Balance!=0.0&&Martingale==True){if(Balance>AccountBalance())Lots=Multiplier*Lots;else if((Balance+MinProfit)<AccountBalance())Lots=Lots/Multiplier;else if((Balance+MinProfit)>=AccountBalance()&&Balance<=AccountBalance())Lots=Lots;}Balance=AccountBalance();

// expert init positions
int cnt=0,OP=0,OS=0,OB=0,CS=0,CB=0;OP=0;for(cnt=0;cnt<OrdersTotal();cnt++){OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
if((OrderType()==OP_SELLSTOP||OrderType()==OP_BUYSTOP)&&OrderSymbol()==Symbol()&&((OrderMagicNumber()==Magic)||Magic==0))OP=OP+1;}
if(OP>=1){OS=0; OB=0;}OB=0;OS=0;CB=0;CS=0;

// expert conditions to open position
if(SV>0){OS=1;OB=0;}if(BV>0){OB=1;OS=0;}

// expert conditions to close position
if((SV>0)||(TIFI=="true")||(EnableRealSL&&(OrderOpenPrice()-Bid)/Point>=RealSL)||(EnableRealTP&&(Ask-OrderOpenPrice())/Point>=RealTP)){CB=1;}
if((BV>0)||(TIFI=="true")||(EnableRealSL&&(Ask-OrderOpenPrice())/Point>=RealSL)||(EnableRealTP&&(OrderOpenPrice()-Bid)/Point>=RealTP)){CS=1;}
for(cnt=0;cnt<OrdersTotal();cnt++){OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
if(OrderType()==OP_BUY&&OrderSymbol()==Symbol()&&((OrderMagicNumber()==Magic)||Magic==0)){if(CB==1){OrderClose(OrderTicket(),OrderLots(),Bid,Slip,Red);return(0);}}
if(OrderType()==OP_SELL&&OrderSymbol()==Symbol()&&((OrderMagicNumber()==Magic)||Magic==0)){if(CS==1){OrderClose(OrderTicket(),OrderLots(),Ask,Slip,Red);return(0);}}}double SLI=0,TPI=0;int TK=0;

// expert open position value
if((AddP()&&AddPositions&&OP<=MaxOrders)||(OP==0&&!AddPositions)){
if(OS==0&&OB==0){Comment("no order opened");}
if(OS==1){if(Time0!=Time[0]){if(TP==0)TPI=0;else TPI=(Low[i]-XpipsOverUnder*Point)-TP*Point;if(SL==0)SLI=0;else SLI=(Low[i]-XpipsOverUnder*Point)+SL*Point;TK=OrderSend(Symbol(),OP_SELLSTOP,Lots,Low[i]-XpipsOverUnder*Point,Slip,SLI,TPI,OrSt,Magic,expire,Red);OS=0;Comment("sell order opened","\n","magic number : ",Magic);Time0=Time[0];if(TK>0)TradePerBar++;return(0);}}	
if(OB==1){if(Time0!=Time[0]){if(TP==0)TPI=0;else TPI=(High[i]+XpipsOverUnder*Point)+TP*Point;if(SL==0)SLI=0;else SLI=(High[i]+XpipsOverUnder*Point)-SL*Point;TK=OrderSend(Symbol(),OP_BUYSTOP,Lots,High[i]+XpipsOverUnder*Point,Slip,SLI,TPI,OrSt,Magic,expire,Lime);OB=0;Comment("buy order opened","\n","magic number : ",Magic);Time0=Time[0];if(TK>0)TradePerBar++;return(0);}}}
for(j=0;j<OrdersTotal();j++){if(OrderSelect(j,SELECT_BY_POS,MODE_TRADES)){if(OrderSymbol()==Symbol()&&((OrderMagicNumber()==Magic)||Magic==0)){TrP();}}}return(0);}

// expert number of orders
int CntO(int Type,int Magic){int _CntO;_CntO=0;
for(int j=0;j<OrdersTotal();j++){OrderSelect(j,SELECT_BY_POS,MODE_TRADES);if(OrderSymbol()==Symbol()){if((OrderType()==Type&&(OrderMagicNumber()==Magic)||Magic==0))_CntO++;}}return(_CntO);}

//expert breakeven
void TrP(){double pb,pa,pp;pp=MarketInfo(OrderSymbol(),MODE_POINT);if(OrderType()==OP_BUY){pb=MarketInfo(OrderSymbol(),MODE_BID);
if(BE>0){if((pb-OrderOpenPrice())>BE*pp){if((OrderStopLoss()-OrderOpenPrice())<0){ModSL(OrderOpenPrice()+0*pp);}}}

// expert trailing stop
if(TS>0){if((pb-OrderOpenPrice())>TS*pp){if(OrderStopLoss()<pb-(TS+TSStep-1)*pp){ModSL(pb-TS*pp);return;}}}}
if(OrderType()==OP_SELL){pa=MarketInfo(OrderSymbol(),MODE_ASK);if(BE>0){if((OrderOpenPrice()-pa)>BE*pp){if((OrderOpenPrice()-OrderStopLoss())<0){ModSL(OrderOpenPrice()-0*pp);}}}
if(TS>0){if(OrderOpenPrice()-pa>TS*pp){if(OrderStopLoss()>pa+(TS+TSStep-1)*pp||OrderStopLoss()==0){ModSL(pa+TS*pp);return;}}}}}

//expert stoploss
void ModSL(double ldSL){bool fm;fm=OrderModify(OrderTicket(),OrderOpenPrice(),ldSL,OrderTakeProfit(),0,CLR_NONE);}

//expert add positions function
bool AddP(){int _num=0; int _ot=0;
for (int j=0;j<OrdersTotal();j++){if(OrderSelect(j,SELECT_BY_POS)==true && OrderSymbol()==Symbol()&&OrderType()<3&&((OrderMagicNumber()==Magic)||Magic==0)){	
_num++;if(OrderOpenTime()>_ot) _ot=OrderOpenTime();}}if(_num==0) return(true);if(_num>0 && ((Time[0]-_ot))>0) return(true);else return(false);

if(TK<0){if (GetLastError()==134){err=1;Print("NOT ENOGUGHT MONEY!!");}return (-1);}}


