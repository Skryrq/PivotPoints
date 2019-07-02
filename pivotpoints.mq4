//+------------------------------------------------------------------+
//|                                                  PivotPoints.mq4 |
//|                                                               MP |
//+------------------------------------------------------------------+
#property copyright "MP"
#property link      ""
#property version   "1.00"
#property strict

input int TrailingStopTriggerPips=50;
input int TrailingStopPips=20;

input double MinimalPriceMovePips=0;
input int CandleType=0;
input int magicnumber=1;
input string Time_Settings="-----------------------------Time settings-----------------------------";
input bool NewYorkTimeBased=0;

input string Risk_Management="---------------------------Risk Management---------------------------";
input bool ActiveEquitySecurity=0;
input double MaxLossPercent=10;
input bool AutoSizing=0;
input double ManuallySetSize=0.1;
input double MaxLossPercentPerTrade=0.5;

//+------------------------------------------------------------------+
//| Functions                                                        |
//+------------------------------------------------------------------+ 
long chartID=ChartID();
double equity;
double balance;
double initialbalance=AccountBalance();

double orderopenprice;//=1.14500;
double stoplossprice;//=1.14400;

double size=0;

string basecurrency,quotecurrency,conversionsymbol;
double exchangerate;
double lotstep= MarketInfo(NULL,MODE_LOTSTEP);
int currencycases=4;
int conversiondigits=0;
int symboldigits=(int)MarketInfo(Symbol(),MODE_DIGITS);
int basicunitdigits=5;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateSize(bool USDonpair,bool invertedratio)
  {
   balance=AccountBalance();
   double sizing=0;
   double stoploss=0;
   //Print(orderopenprice);Print(stoplossprice);
   if(orderopenprice>stoplossprice) {stoploss=((orderopenprice-stoplossprice)*MathPow(10,symboldigits));}
   if(orderopenprice<stoplossprice) {stoploss=((stoplossprice-orderopenprice)*MathPow(10,symboldigits));}
   if(orderopenprice==stoplossprice){stoploss=0.00001;} //avoid divide by 0 critical error
   double maxlossUSD=((MaxLossPercentPerTrade/100.)*balance);   //Print(maxlossUSD);
   
   //Print(stoploss);
   if(USDonpair==1 && invertedratio==0)
     {
      double currenciesdigitsratio=(MathPow(10,symboldigits)/MathPow(10,basicunitdigits));
      double maxlossUSDperpip=maxlossUSD/stoploss;
      sizing=maxlossUSDperpip*currenciesdigitsratio; //Print("sizing=",sizing);
     }
   if(USDonpair==1 && invertedratio==1)
     {
      double currenciesdigitsratio=(MathPow(10,symboldigits)/MathPow(10,basicunitdigits));
      double maxlossXXX=maxlossUSD*Bid; //Print("maxlossXXX=",maxlossXXX);
      double maxlossXXXperpip=maxlossXXX/stoploss; //Print("maxlossXXXperpip=",maxlossXXXperpip);
      sizing=maxlossXXXperpip*currenciesdigitsratio; //Print("sizing=",sizing);
     }
   if(USDonpair==0 && invertedratio==0)
     {
      double currenciesdigitsratio=(MathPow(10,conversiondigits)/MathPow(10,basicunitdigits)); Print(currenciesdigitsratio);
      double maxlossconverted = maxlossUSD*(1./exchangerate); //Print("maxlossconverted=",maxlossconverted);
      double maxlossXXXperpip = maxlossconverted/stoploss;
      sizing=maxlossXXXperpip*currenciesdigitsratio; //Print("sizing=",sizing);
     }
   if(USDonpair==0 && invertedratio==1)
     {
      double currenciesdigitsratio=(MathPow(10,conversiondigits)/MathPow(10,basicunitdigits)); Print(currenciesdigitsratio);
      double maxlossconverted = maxlossUSD*(exchangerate); //Print("maxlossconverted=",maxlossconverted);
      double maxlossXXXperpip = maxlossconverted/stoploss;
      sizing=maxlossXXXperpip*currenciesdigitsratio; //Print("sizing=",sizing);
     }
   size=MathRound(sizing/lotstep)*lotstep; Print("size=",size);
   return(size);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Sizing(bool automated)
  {
   if(automated==0){return(ManuallySetSize);}
   if(automated)
     {
      basecurrency=StringSubstr(Symbol(),0,3);
      quotecurrency=StringSubstr(Symbol(),3,3);
      if(quotecurrency=="USD"){currencycases=0;}
      if(basecurrency=="USD"){currencycases=1;}

      if(quotecurrency!="USD" && basecurrency!="USD")
        {
         for(int i=0;i<SymbolsTotal(0);i++)
           {
            string selectedsymbol=SymbolName(i,0);
            string selectedbasecurrency=StringSubstr(selectedsymbol,0,3);
            string selectedquotecurrency=StringSubstr(selectedsymbol,3,3);
            if(quotecurrency==selectedbasecurrency && selectedquotecurrency=="USD")
              {
               conversionsymbol=selectedsymbol;
               exchangerate=SymbolInfoDouble(selectedsymbol,SYMBOL_BID);
               conversiondigits=(int)SymbolInfoInteger(selectedsymbol,SYMBOL_DIGITS); 
               currencycases=2;
               Print(selectedsymbol);
              }
            if(quotecurrency==selectedquotecurrency && selectedbasecurrency=="USD")
              {
               conversionsymbol=selectedsymbol;
               exchangerate=SymbolInfoDouble(selectedsymbol,SYMBOL_BID); 
               conversiondigits=(int)SymbolInfoInteger(selectedsymbol,SYMBOL_DIGITS); 
               currencycases=3;
               Print(selectedsymbol);
              }
           }
        }
      //IT SHOULD TAKE INTO ACCOUNT THE DIFFERENCE BASE AND QUOTE CURRENCIES DIGITS FOR THE VALUE PER PIP  
      switch(currencycases)
        {
         case 0 : Print("case 0 => XXX/USD"); // XXX/USD                     
         CalculateSize(1,0);
         break;
         case 1 : Print("case 1 => USD/XXX"); // USD/XXX
         CalculateSize(1,1);
         break;
         case 2 : Print("case 2 => YYY/XXX check for exchange");  // YYY/XXX -> check for YYY/USD exchanging pair
         CalculateSize(0,0);
         break;
         case 3 : Print("case 3 => XXX/YYY check for exchange"); // YYY/XXX -> check for USD/XXX exchanging pair
         CalculateSize(0,1);
         break;
         default: Print("no currency pair found"); break;
        }
     }
   return(size);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllOrders(bool activate)
  {
   if(activate==1)
     {
      equity=AccountEquity();
      balance=AccountBalance();
      double percentremaining=(equity/initialbalance);
      double percentloss=(1-percentremaining);

      if(percentloss>(MaxLossPercent/100))
        {
         for(int i=OrdersTotal()-1; i>=0; i --)
           {
            bool os=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
            if(OrderType()==OP_BUY)
              {bool od=OrderClose(OrderTicket(),OrderLots(),Bid,3,clrViolet);}
            if(OrderType()==OP_SELL)
              {bool od=OrderClose(OrderTicket(),OrderLots(),Ask,3,clrViolet);}
           }
         DeletePendingOrders(1,1,1,1);
         ExpertRemove();
         Print("All orders closed / deleted and expert advisor removed due to excessive equity loss : ",MaxLossPercent,"% of maximum loss bearable reached. Actual balance/initial balance : ",balance,"/",initialbalance);
        }
     }
  }

double buystoploss=0;
double buytakeprofit=0;
double buypendingprice=0;
double sellstoploss=0;
double selltakeprofit=0;
double sellpendingprice=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PlaceOrder(bool buymarket,bool buylimit,bool buystop,bool sellmarket,bool selllimit,bool sellstop)
  {
   size=Sizing(AutoSizing);
   if(sellmarket)
     {
      ResetLastError();
      int ticket=OrderSend(Symbol(),OP_SELL,size,Bid,3,sellstoploss,selltakeprofit,"Sell",magicnumber,0,clrRed);
      if(ticket<0){Print("Sell OrderSend error = ",GetLastError());}
      else Print("Sell order opened #",ticket);
     };
   if(sellstop)
     {
      ResetLastError();
      int ticket=OrderSend(Symbol(),OP_SELLSTOP,size,sellpendingprice,3,sellstoploss,selltakeprofit,"SellStop",magicnumber,0,clrRed);
      if(ticket<0){Print("Sell OrderSend error = ",GetLastError());}
      else Print("SellStop order opened #",ticket);
     };
   if(selllimit)
     {
      ResetLastError();
      int ticket=OrderSend(Symbol(),OP_SELLLIMIT,size,sellpendingprice,3,sellstoploss,selltakeprofit,"SellLimit",magicnumber,0,clrRed);
      if(ticket<0){Print("SellLimit OrderSend error = ",GetLastError());}
      else Print("SellLimit order opened #",ticket);
     };
   if(buymarket)
     {
      ResetLastError();
      int ticket=OrderSend(Symbol(),OP_BUY,size,Ask,3,buystoploss,buytakeprofit,"Buy",magicnumber,0,clrGreen);
      if(ticket<0){Print("Buy OrderSend error = ",GetLastError());}
      else Print("Buy order opened #",ticket);
     };
   if(buystop)
     {
      ResetLastError();
      int ticket=OrderSend(Symbol(),OP_BUYSTOP,size,buypendingprice,3,buystoploss,buytakeprofit,"BuyStop",magicnumber,0,clrGreen);
      if(ticket<0){Print("Buystop OrderSend error = ",GetLastError());}
      else Print("BuyStop order opened #",ticket);
     };
   if(buylimit)
     {
      ResetLastError();
      int ticket=OrderSend(Symbol(),OP_BUYLIMIT,size,buypendingprice,3,buystoploss,buytakeprofit,"BuyLimit",magicnumber,0,clrGreen);
      if(ticket<0){Print("BuyLimit OrderSend error = ",GetLastError());}
      else Print("BuyLimit order opened #",ticket);
     };
  }

//==Pivot Point=========================================================

//time converting : summer time GMT+2 / standard time GMT+1 ----------- GMT to EST : -4 => summer time Switzerland -6 / standard Switzerland -5
double pp=0;
double r[3];
double s[3];
double ri[3];
double si[3];
double levels[15];

int hourshift=0;//serverhour-NYhour;  // OANDA: +7 for backtesting 
datetime anchorpoint0=iTime(NULL,PERIOD_H1,0);  
datetime anchorpointone=iTime(NULL,PERIOD_H1,24);
int serverhour=TimeHour(TimeCurrent());

void CreatePPLines(string name,double price,string text,color clr,int style)
  {  
   ObjectCreate(chartID,name,OBJ_TREND,0,anchorpointone,price,anchorpoint0,price);
   ObjectSetInteger(chartID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chartID,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chartID,name,OBJPROP_RAY,1);
   ObjectSetString(chartID,name,OBJPROP_TEXT,text);  
  }
void SetPivotPoints(bool oninit,color clr)
  {
   serverhour=TimeHour(TimeCurrent());
   int localhour=TimeHour(TimeLocal());
   int hourdifference= serverhour-localhour;
   int NYhour=serverhour-4+(TimeGMTOffset()/3600)-hourdifference; //serverhour-7 for backtesting with OANDA
   int NYtoserverdifference=serverhour-NYhour; //Print(NYtoserverdifference);
   int basePPhour=TimeHour(iTime(NULL,PERIOD_H1,0));

   double high=0;
   double low=0;
   double close=0;
   int midnightbar=1;
   
   if(oninit==1)
   {
      if(NewYorkTimeBased==0){hourshift=0;Print("Timebase: broker");}   
      if(NewYorkTimeBased==1){hourshift=7;Print("Timebase: New York");} 
      for(int i=1;i<25;i++)
         {
         if(TimeHour(iTime(NULL,PERIOD_H1,i))==hourshift)
            {
            //Print(TimeHour(iTime(NULL,PERIOD_H1,i)));Print(i);
            midnightbar=i+1;            
            break;
            }
         }
    }  
   int lastmidnightbar=midnightbar+23;
   anchorpointone=iTime(NULL,PERIOD_H1,midnightbar);
   datetime midnight=iTime(NULL,PERIOD_H1,midnightbar);
   datetime lastmidnight=iTime(NULL,PERIOD_H1,lastmidnightbar);
   high=iHigh(NULL,PERIOD_H1,iHighest(NULL,PERIOD_H1,MODE_HIGH,23,midnightbar));
   low=iLow(NULL,PERIOD_H1,iLowest(NULL,PERIOD_H1,MODE_LOW,23,midnightbar));
   close=iClose(NULL,PERIOD_H1,midnightbar);
   //Print(midnightbar);
   if((NewBar(PERIOD_H1,0) && hourshift==basePPhour)   ||  (oninit==1))
   {
      anchorpoint0=iTime(NULL,PERIOD_H1,0);
      
      ObjectsDeleteAll();
      DeletePendingOrders(1,1,1,1);
      ChartSetInteger(chartID,CHART_SHOW_OBJECT_DESCR,1);
      //Print(high);Print(low);Print(close);
      ObjectCreate(chartID,"PP calculation's end",OBJ_VLINE,0,midnight,0);
      ObjectCreate(chartID,"PP calculation's start",OBJ_VLINE,0,lastmidnight,0);
      //basic levels
      pp    = levels[7]    = (high+low+close)/3; CreatePPLines("Pivot point",pp,"L7-Pivot point",clr,0);
      r[0]  = levels[9]    = (2*pp)-low; CreatePPLines("R1",r[0],"L9-R1",clrDarkOrange,0);
      r[1]  = levels[11]   = pp+(high-low);CreatePPLines("R2",r[1],"L11-R2",clrDarkOrange,0);
      r[2]  = levels[13]   = high+2*(pp-low);CreatePPLines("R3",r[2],"L13-R3",clrDarkOrange,0);         
      s[0]  = levels[5]    = (2*pp)-high; CreatePPLines("S1",s[0],"L5-S1",clrDarkOrange,0);
      s[1]  = levels[3]    = pp-(high-low); CreatePPLines("S2",s[1],"L3-S2",clrDarkOrange,0);
      s[2]  = levels[1]    = low-2*(high-pp); CreatePPLines("S3",s[2],"L1-S3",clrDarkOrange,0);      
      //intermediate levels
      ri[0] = levels[8]    = pp+((r[0]-pp)/2); CreatePPLines("Ri1",ri[0],NULL,clrCrimson,2);
      ri[1] = levels[10]   = r[0]+((r[1]-r[0])/2);CreatePPLines("Ri2",ri[1],NULL,clrCrimson,2);
      ri[2] = levels[12]   = r[1]+((r[2]-r[1])/2);CreatePPLines("Ri3",ri[2],NULL,clrCrimson,2);         
      si[0] = levels[6]    = pp-((pp-s[0])/2); CreatePPLines("Si1",si[0],NULL,clrCrimson,2);
      si[1] = levels[4]    = s[0]-((s[0]-s[1])/2); CreatePPLines("Si2",si[1],NULL,clrCrimson,2);
      si[2] = levels[2]    = s[1]-((s[1]-s[2])/2); CreatePPLines("Si3",si[2],NULL,clrCrimson,2);   
      levels[0]  =  PriceNormalization(levels[1],-100);
      levels[14] =  PriceNormalization(levels[13],100);
      
   }
   anchorpointone=iTime(NULL,PERIOD_H1,lastmidnightbar);
   //Time0=iTime(NULL,PERIOD_H1,0);
  }

//==check conditions===================================================
double PriceNormalization(double price,int addedpips)
  {
   int digits= (int) MarketInfo(NULL,MODE_DIGITS);
   double ticksize=MarketInfo(NULL,MODE_TICKSIZE);
   double addepipstodigits=addedpips/(MathPow(10,digits));
   double tonormalize=price+addepipstodigits;
   return( MathRound(((tonormalize)/ticksize))*ticksize);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CheckCandleShape(int shift, int period, double mincandlespread, bool printer)
{
string candlename="";
int i=0;
bool bearish=0;
bool bullish=0;
double close1=iClose(NULL,period,shift);
double open1=iOpen(NULL,period,shift);
double low1=iLow(NULL,period,shift);
double high1=iHigh(NULL,period,shift);
double candlespread=1, candlespreadpips=0, 
   bodypips=0,lowershadowpips=0,uppershadowpips=0,   // define minimal pips to compare to 
   body=0,lowershadow=0,uppershadow=0,
   bodyratio=0,lowershadowratio=0,uppershadowratio=0;

//________________________________________CANDLESHAPES_____________________________________________  
   
   if(close1>open1)             //bullish
      {
      bullish=true;
      body=close1-open1;
      lowershadow=open1-low1;
      uppershadow=high1-close1;
      candlespread=high1-low1;
      }
   if(close1<open1)             //bearish
      {
      bearish=true;
      body=open1-close1;
      lowershadow=close1-low1;
      uppershadow=high1-open1;
      candlespread=high1-low1;
      }
    if(candlespread==0)         //none
      {candlespread=1;}
      bodyratio=body/candlespread;
      lowershadowratio=lowershadow/candlespread;
      uppershadowratio=uppershadow/candlespread; 

//    BULLISH  ========================================================================================
if(bullish==1)
{
// 1 : HAMMER    
   if(
   (bodyratio<0.33)
   &&(bodyratio>0.1)
   &&(uppershadowratio<0.1)
   &&(lowershadowratio>0.66)
   &&(candlespread>mincandlespread)
   )
   {i=1; candlename="hammer";} //Print(i);
// 2 : MARUBOZU 
   if(
   (bodyratio>0.9)
   &&(uppershadowratio<0.1)
   &&(lowershadowratio<0.1)
   &&(candlespread>mincandlespread)
   )
   {i=2;candlename="marubozu";} //Print(i);
// 3 : OPENING MARUBOZU
   if(
   (bodyratio>0.5)
   &&(uppershadowratio<0.1)
   &&(lowershadowratio>0.3)
   &&(candlespread>mincandlespread)
   )
   {i=3;candlename="opening marubozu";} //Print(i);
// 4 : CLOSING MARUBOZU 
   if(
   (bodyratio<0.5)
   &&(uppershadowratio<0.3)
   &&(lowershadowratio>0.1)
   &&(candlespread>mincandlespread)
   )
   {i=4;candlename="closing marubozu";} //Print(i);
// 5 : HANGING MAN
   if(
   (bodyratio<0.33)
   &&(bodyratio>0.1)
   &&(uppershadowratio>0.66)
   &&(lowershadowratio<0.1)
   &&(candlespread>mincandlespread)
   )
   {i=5;candlename="hanging man";} //Print(i);
}

//    BEARISH
// -1 : HAMMER  ========================================================================================
if(bearish==1)
{
   if(
   (bodyratio<0.33)
   &&(bodyratio>0.1)
   &&(lowershadowratio<0.1)
   &&(uppershadowratio>0.66)
   &&(candlespread>mincandlespread)
   )
   i=-1;
}
//    DOJI
if(bearish||bullish)
{
// 10 : LONG-LEGGED
   if(
   (bodyratio<0.15)
   &&(lowershadowratio>0.4)
   &&(uppershadowratio>0.4)
   &&(candlespread>mincandlespread)
   )
   i=10;
// 11 : DRAGONFLY
   if(
   (bodyratio<0.1)
   &&(lowershadowratio>0.7)
   &&(uppershadowratio<0.3)
   &&(candlespread>mincandlespread)
   )
   i=11;
// 12 : GRAVESTONE
   if(
   (bodyratio<0.1)
   &&(lowershadowratio<0.3)
   &&(uppershadowratio>0.7)
   &&(candlespread>mincandlespread)
   )
   i=12;
}
if(printer==1)Print("Candleshape=",i," : ",candlename,", shift=",shift);
return(i);
}











//========delete pending===================================
void DeletePendingOrders(bool buylimit,bool buystop,bool selllimit,bool sellstop)
  {
   for(int i=OrdersTotal()-1; i>=0; i --)
     {
      bool od;
      bool os=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if((OrderSymbol()==Symbol()) && (OrderMagicNumber()==magicnumber))
        {
         if(buylimit==1 && OrderType()==2)od=OrderDelete(OrderTicket());
         if(buystop==1 && OrderType()==4)od=OrderDelete(OrderTicket());
         if(selllimit==1 && OrderType()==3)od=OrderDelete(OrderTicket());
         if(sellstop==1 && OrderType()==5)od=OrderDelete(OrderTicket());
        }
     }
  }
//========Break out stop loss===================================
bool firstbreakout;
bool secondbreakout;
double sellfirstbreakpoint;
double sellfirststoploss;
double sellsecondbreakpoint;
double sellsecondstoploss;

double buyfirstbreakpoint;
double buyfirststoploss;
double buysecondbreakpoint;
double buysecondstoploss;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateHLines(string name,double price,string text,color clr)
  {
   ObjectCreate(chartID,name,OBJ_HLINE,0,0,price);
   ObjectSetInteger(chartID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chartID,name,OBJPROP_STYLE,3);
   ObjectSetString(chartID,name,OBJPROP_TEXT,text);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteBPObjects(int buysell) // 0 : buy / 1 : sell / 2 : both
  {
   if((buysell==0) || (buysell==2))
     {
      ObjectDelete(chartID,"buy breakpoint 1");
      ObjectDelete(chartID,"buy stoploss 1");
      ObjectDelete(chartID,"buy breakpoint 2");
      ObjectDelete(chartID,"buy stoploss 2");
     }
   if((buysell==1) || (buysell==2))
     {
      ObjectDelete(chartID,"sell breakpoint 1");
      ObjectDelete(chartID,"sell stoploss 1");
      ObjectDelete(chartID,"sell breakpoint 2");
      ObjectDelete(chartID,"sell stoploss 2");
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountOrder(bool buymarket,bool buylimit,bool buystop,bool sellmarket,bool selllimit,bool sellstop) // buy : 0-2-4 sell : 1-3-5
  {
   int count=0;
   for(int i=OrdersTotal()-1; i>=0; i --)
     {
      bool os=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if((OrderSymbol()==Symbol()) && (OrderMagicNumber()==magicnumber))
        {
         if(buymarket==1 && OrderType()==0)count++;
         if(buylimit==1 && OrderType()==2)count++;
         if(buystop==1 && OrderType()==4)count++;
         if(sellmarket==1 && OrderType()==1)count++;
         if(selllimit==1 && OrderType()==3)count++;
         if(sellstop==1 && OrderType()==5)count++;
        }
     }
   return(count);
   count=0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BreakOutStop(bool setlines)
  {
   PriceNormalization(buyfirstbreakpoint,0);
   PriceNormalization(buyfirststoploss,0);
   PriceNormalization(buysecondbreakpoint,0);
   PriceNormalization(buysecondstoploss,0);
   if(setlines==1)
     {
      firstbreakout=1;
      DeleteBPObjects(2);
      //buy
      CreateHLines("buy breakpoint 1",buyfirstbreakpoint,"   buy bp 1",clrBlue);
      CreateHLines("buy stoploss 1",buyfirststoploss,"   buy sl 1",clrRed);
      CreateHLines("buy breakpoint 2",buysecondbreakpoint,"   buy bp 2",clrBlue);
      CreateHLines("buy stoploss 2",buysecondstoploss,"   buy sl 2",clrRed);
      //sell
      CreateHLines("sell breakpoint 1",sellfirstbreakpoint,"   sell bp 1",clrBlue);
      CreateHLines("sell stoploss 1",sellfirststoploss,"   sell sl 1",clrRed);
      CreateHLines("sell breakpoint 2",sellsecondbreakpoint,"   sell bp 2",clrBlue);
      CreateHLines("sell stoploss 2",sellsecondstoploss,"   sell sl 2",clrRed);
     }
//Print(BuyFirstBreakpoint);
   for(int i=OrdersTotal()-1; i>=0; i --)
      {
      bool os=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if((OrderType()==OP_BUY) && (OrderSymbol()==Symbol()) && (OrderMagicNumber()==magicnumber))
        {
         if((buyfirstbreakpoint<Bid) && (OrderTakeProfit()!=buyfirstbreakpoint) && (firstbreakout==1))
           {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),buyfirststoploss,OrderTakeProfit(),0,clrBlue);
            firstbreakout=0;
           }
         if((buysecondbreakpoint<Bid) && (OrderTakeProfit()!=buysecondbreakpoint) && (secondbreakout==1))
           {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),buysecondstoploss,OrderTakeProfit(),0,clrBlue);
           }
        }
       if((OrderType()==OP_SELL) && (OrderSymbol()==Symbol()) && (OrderMagicNumber()==magicnumber))
           {
            if((sellfirstbreakpoint>Ask) && (OrderTakeProfit()!=sellfirstbreakpoint) && (firstbreakout==1))
              {
               bool res=OrderModify(OrderTicket(),OrderOpenPrice(),sellfirststoploss,OrderTakeProfit(),0,clrBlue);
               firstbreakout=0;
              }
            if((sellsecondbreakpoint>Ask) && (OrderTakeProfit()!=sellsecondbreakpoint) && (secondbreakout==1))
              {
               bool res=OrderModify(OrderTicket(),OrderOpenPrice(),sellsecondstoploss,OrderTakeProfit(),0,clrBlue);
              }
           }
      }
  }

void TrailingStop(int profitwhentotrigger, int trailingpips)
{
static bool triggered=0;
double triggeringprice=0;

for(int i=OrdersTotal()-1; i>=0; i --)
      {
      bool os=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if((OrderType()==OP_BUY) && (OrderSymbol()==Symbol()) && (OrderMagicNumber()==magicnumber))
        {
         double newstoploss=PriceNormalization(Bid,-trailingpips);
         triggeringprice=PriceNormalization(OrderOpenPrice(), profitwhentotrigger);
         if((triggeringprice<Bid && triggered==0) || (triggered && OrderStopLoss()<newstoploss))
           {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),newstoploss,OrderTakeProfit(),0,clrBlue); triggered=1;
           }
        }
 
       if((OrderType()==OP_SELL) && (OrderSymbol()==Symbol()) && (OrderMagicNumber()==magicnumber))
          {
         double newstoploss=PriceNormalization(Ask,trailingpips);
         triggeringprice=PriceNormalization(OrderOpenPrice(), -profitwhentotrigger);
         if((triggeringprice>Ask && triggered==0) || (triggered && OrderStopLoss()<newstoploss))
           {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),newstoploss,OrderTakeProfit(),0,clrBlue); triggered=1;
           }
        }
      }
if(CountOrder(1,0,0,1,0,0)==0)triggered=0;
}
bool CheckHourOpening(int openinghour)
{
int hournow=TimeHour(TimeCurrent());
if(hournow==openinghour)return(true);
return(false);
}

bool CheckTime(bool USD, bool EUR, bool JPY, bool GBP)
{
   bool USDcheck=0, EURcheck=0, JPYcheck=0, GBPcheck=0;
   int hournow=TimeHour(TimeCurrent());      // broker's time
   int USDopenhour=14, USDclosehour=23;
   int EURopenhour=9, EURclosehour=21;
   int JPYopenhour=0, JPYclosehour=9;
   int GBPopenhour=8, GBPclosehour=17;
   
   if(USD)  {if((hournow>=USDopenhour)&&(hournow<USDclosehour)) USDcheck=1;}
   if(EUR)  {if((hournow>=EURopenhour)&&(hournow<EURclosehour)) EURcheck=1;}
   if(JPY)  {if((hournow>=JPYopenhour)&&(hournow<JPYclosehour)) JPYcheck=1;}
   if(GBP)  {if((hournow>=GBPopenhour)&&(hournow<GBPclosehour)) GBPcheck=1;}
   
   if(USDcheck||EURcheck||JPYcheck||GBPcheck) return(true);
   
   return(false);
}

double CheckPriceMove(int bars,int timeframe,int shift, bool openclose, bool highlow, bool printer)
{  
   bool bullish=0;
   double pricemove[24]; ArrayInitialize(pricemove,0);
   double maxmove[24]; ArrayInitialize(maxmove,0);
   double averagemove=0;
   double averagemaxmove=0;
   
   for(int i=shift;i<bars;i++)
        {
        double high=iHigh(NULL,timeframe,i);
        double low=iLow(NULL,timeframe,i);
        double open=iOpen(NULL,timeframe,i);
        double close=iClose(NULL,timeframe,i);
        
        if(open<close) //bullish
           {
           pricemove[i]=PriceNormalization(+(close-open),0);
           maxmove[i]=PriceNormalization(+(high-low),0);
           }
        if(open>close) //bearish
           {
           pricemove[i]=PriceNormalization(-(open-close),0);
           maxmove[i]=PriceNormalization(-(high-low),0);
           }
        
        averagemove=averagemove+pricemove[i];
        averagemaxmove=averagemaxmove+maxmove[i];
        //Print("price:",PriceNormalization(pricemove[i],0));
        //Print("AM:",PriceNormalization(averagemove,0));
        }
if(printer==1)
{
Print("maxM:",PriceNormalization(averagemaxmove,0));   
Print("averageM:",PriceNormalization(averagemove,0));   
}
if(openclose==1)return(averagemove);
if(highlow==1)return(averagemaxmove);
return(0);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+   
int OnInit()
  {  
   SetPivotPoints(1,clrWhite);
   
   for(int i=1;i<14;i++)
   {
   if((Bid>levels[i]) && Bid<levels[i+1])
   currentrange=i;
   }
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
int MAcrossing(int timeframe, int slowperiod, int fastperiod, int mode, int shift)
{
  double fastma0=iMA(NULL,timeframe,fastperiod,0,mode,PRICE_CLOSE,shift);
  double fastma1=iMA(NULL,timeframe,fastperiod,0,mode,PRICE_CLOSE,shift+1);
  double slowma0=iMA(NULL,timeframe,slowperiod,0,mode,PRICE_CLOSE,shift);
  double slowma1=iMA(NULL,timeframe,slowperiod,0,mode,PRICE_CLOSE,shift+1);
if(fastma0>slowma0 && fastma1<slowma1)return(1);
if(fastma0<slowma0 && fastma1>slowma1)return(-1);
return(0);
}

bool NewBar(int timeframe, int contextnumber) 
{
static datetime time[10];
if(time[contextnumber]==iTime(NULL,timeframe,0))return(false);
time[contextnumber]=iTime(NULL,timeframe,0);
return(true);
}






bool TradeOnOff=0;
static double currentbid=Bid;
static int currentrange;
void CheckConditions()
  { 
  bool uptrend=0; 
  double previousbid = currentbid; 
  currentbid = Bid; 
  if (currentbid > previousbid) uptrend=1;
  if (currentbid < previousbid) uptrend=0;
  //Print(previousbid); Print(currentbid);Print(uptrend);
  
  bool rangeswitch=0;
  int previousrange=currentrange;
  for(int i=1;i<14;i++)
   {
   if((Bid>levels[i]) && Bid<levels[i+1])
   currentrange=i;
   //Print("Bid between: ",levels[i]," and ",levels[i+1]);
   }
  if (currentrange != previousrange){rangeswitch=1;}// Print(currentrange);
  
  //indicators 
  double lasthighest=iHigh(NULL,PERIOD_H1,iHighest(NULL,PERIOD_H1,MODE_HIGH,5,0));
  double lastlowest=iLow(NULL,PERIOD_H1,iLowest(NULL,PERIOD_H1,MODE_HIGH,5,0));
  
  double h4ma0=iMA(NULL,PERIOD_H4,5,0,MODE_SMA,PRICE_CLOSE,0);
  double d1ma0=iMA(NULL,PERIOD_D1,5,0,MODE_SMA,PRICE_CLOSE,0);
  double fastma0=iMA(NULL,PERIOD_H1,5,0,MODE_SMA,PRICE_CLOSE,0);
  double slowma0=iMA(NULL,PERIOD_H1,10,0,MODE_SMA,PRICE_CLOSE,0);
  double fastma1=iMA(NULL,PERIOD_H1,5,0,MODE_SMA,PRICE_CLOSE,1);
  double slowma1=iMA(NULL,PERIOD_H1,10,0,MODE_SMA,PRICE_CLOSE,1);
if(NewBar(PERIOD_H1,1))TradeOnOff=1;  
//=================MARKET OPENING===========================================================================
if(NewBar(PERIOD_H1,2))
{

if( 
     (CheckHourOpening(9) 
     && (CountOrder(1,1,1,1,1,1)<1)
     //&& (CheckCandleShape(1,PERIOD_D1,0.00200,0)==2)
     //&& (CheckCandleShape(0,PERIOD_H1,0.00050,0)==2)  
     //&& (Bid>h4ma0)
     //&& (Bid>d1ma0)
     //&& (CheckPriceMove(1,PERIOD_D1,0,1,0,0)>MinimalPriceMovePips/100000)
     && (CheckPriceMove(7,PERIOD_H1,0,1,0,0)>MinimalPriceMovePips/100000)
     )) 
     {  //buy
        buypendingprice=orderopenprice=PriceNormalization(Bid,0);
        stoplossprice=buystoploss=PriceNormalization(Bid,-50); 
        buytakeprofit=PriceNormalization(Bid,+100);
        //buytakeprofit=PriceNormalization(levels[currentrange+1],0);
      //{PlaceOrder(1,0,0,0,0,0);}
      //Print("blabla");
      }  
}        
//=================TRENDFOLLOWING===========================================================================

if( 
     (CheckTime(1,1,0,0)
     && (TradeOnOff==1)
     && (CountOrder(1,1,1,1,1,1)<1)
     //&& (CheckCandleShape(1,PERIOD_D1,0.00200,0)==2)
     //&& (CheckCandleShape(0,PERIOD_H1,0.00050,0)==2)
     && (MAcrossing(PERIOD_H1,10,5,1,0)==1)
     //&& (Bid>h4ma0)
     && (Bid>d1ma0)
     && (CheckPriceMove(1,PERIOD_D1,0,1,0,0)>MinimalPriceMovePips/100000)
     )) 
     {  //buy
        buypendingprice=orderopenprice=PriceNormalization(Bid,0);
        stoplossprice=buystoploss=PriceNormalization(iLow(NULL,PERIOD_H1,0),-50); 
        buytakeprofit=PriceNormalization(levels[currentrange+1],0);
      {PlaceOrder(1,0,0,0,0,0);TradeOnOff=0;}
      }  
        

//=================RANGESWITCH===========================================================================
  if((rangeswitch==1) && (CountOrder(1,1,1,1,1,1)<1) && (currentrange>2) && (currentrange<12))
  {   
     if( 
     (CheckPriceMove(1,PERIOD_H1,0,1,0,0)>MinimalPriceMovePips/100000)  
     && (CheckCandleShape(0,PERIOD_H1,0,0)==CandleType)
     //&& (MAcrossing(PERIOD_H1,10,5,0,0)==-1)
     && (CheckTime(1,1,0,0))
     )
     {  //buy
        
        buypendingprice=orderopenprice=PriceNormalization(Bid,0);
         
        
        stoplossprice=buystoploss=PriceNormalization(orderopenprice,-75); 
        buytakeprofit=PriceNormalization(levels[currentrange+1],0);
        
        //{PlaceOrder(1,0,0,0,0,0);}

     }
     
  }
    
  rangeswitch=0;
  } 
void OnTick()
  {  
   SetPivotPoints(0,clrWhite);
   

   CheckConditions(); 
   //TrailingStop(TrailingStopTriggerPips,TrailingStopPips);
   //BreakOutStop(0);
   if(CountOrder(1,1,1,0,0,0)==0){DeleteBPObjects(0);}//firstbreakout=0;secondbreakout=0;}
   if(CountOrder(0,0,0,1,1,1)==0){DeleteBPObjects(1);}//firstbreakout=0;secondbreakout=0;}
   
   if(CountOrder(1,0,0,1,0,0)>0){DeletePendingOrders(1,1,1,1);}
   CloseAllOrders(ActiveEquitySecurity);

  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---

  }


/*
if(uptrend==1)
     {
     if((levels[currentrange]<lasthighest) && (levels[currentrange+1]>lasthighest))
      {      
      buypendingprice=orderopenprice=PriceNormalization(lasthighest,15);
      }
     else buypendingprice=orderopenprice=PriceNormalization(levels[currentrange],15);
     
     stoplossprice=buystoploss=PriceNormalization(last1mlowest,-10); 
     buytakeprofit=PriceNormalization(levels[currentrange+1],0);
     PlaceOrder(0,0,1,0,0,0);
     
     buyfirstbreakpoint=PriceNormalization(orderopenprice,30);
     buyfirststoploss=PriceNormalization(orderopenprice,15);
     BreakOutStop(1);
     }
     
     if(uptrend==0)
     {
     if((levels[currentrange+1]>lastlowest) && (levels[currentrange]<lastlowest))
      {      
      sellpendingprice=orderopenprice=PriceNormalization(lastlowest,-20);
      }
     else sellpendingprice=orderopenprice=PriceNormalization(levels[currentrange+1],-15);
     
     stoplossprice=sellstoploss=PriceNormalization(last1mhighest,+15);                      //levels[currentrange+2],0
     selltakeprofit=PriceNormalization(levels[currentrange],0);
     PlaceOrder(0,0,0,0,0,1);
     
     sellfirstbreakpoint=PriceNormalization(orderopenprice,-30);
     sellfirststoploss=PriceNormalization(orderopenprice,-15);
     BreakOutStop(1);
     }
     /*
     if(uptrend==0)
     {
     orderopenprice=Ask;
     stoplossprice=sellstoploss=PriceNormalization(levels[currentrange+2],0); 
     selltakeprofit=PriceNormalization(levels[currentrange-2],0);
     PlaceOrder(0,0,0,1,0,0);
     }*/