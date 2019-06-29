//+------------------------------------------------------------------+
//|                                                   TestThings.mq4 |
//|                                                               MP |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "MP"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

long chartID= ChartID();
void fibo(int period, int bars,int firstcountbar, color clr)
   {
   int highestshift=iHighest(NULL,period,MODE_HIGH,bars,firstcountbar);
   int lowestshift=iLowest(NULL,period,MODE_LOW,bars,firstcountbar);
   double high=iHigh(NULL,period,highestshift);
   double low=iLow(NULL,period,lowestshift);
   
   //correctivhigh
   
   datetime anchorone = iTime(NULL,period,highestshift);
   datetime anchortwo = iTime(NULL,period,lowestshift);
   
   
   string objectname = "Fibo: period=M"+IntegerToString(period)+" bars="+IntegerToString(bars);
   int levels=9;
   
   ObjectCreate(chartID,objectname,OBJ_FIBO,0,anchorone,high,anchortwo,low);
   ObjectSetInteger(chartID,objectname,OBJPROP_LEVELCOLOR,clr);
   ObjectSetInteger(chartID,objectname,OBJPROP_COLOR,clr);
   ObjectSetInteger(chartID,objectname,OBJPROP_WIDTH,2);
   ObjectSetInteger(chartID,objectname,OBJPROP_LEVELS,levels);
   
   double spread = high-low;
   double pricevalues[10];
   double values[10]={0,0.236,0.382,0.5,0.618,0.786,1.0,1.272,1.618};  
   for(int i=0;i<levels;i++)
     {     
      ObjectSetDouble(chartID,objectname,OBJPROP_LEVELVALUE,i,values[i]);
      ObjectSetString(chartID,objectname,OBJPROP_LEVELTEXT,i,DoubleToString(100*values[i],1));
      pricevalues[i]=low+values[i]*spread;    
     } 
   
   };    
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
 fibo(60,50,1,clrDarkOrange);
 fibo(240,30,1,clrRoyalBlue);
 //fibo(1440,70,3,clrViolet);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
ObjectsDeleteAll(chartID);
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
/*
   {long chartID= ChartID();

   //Primary wave
   int highestshift=iHighest(NULL,PERIOD_H4,MODE_HIGH,70,1);
   int lowestshift=iLowest(NULL,PERIOD_H4,MODE_LOW,70,1);
   double high=iHigh(NULL,PERIOD_H4,highestshift);
   double low=iLow(NULL,PERIOD_H4,lowestshift);
   datetime anchorone = iTime(NULL,PERIOD_H4,highestshift);
   datetime anchortwo = iTime(NULL,PERIOD_H4,lowestshift);
   
   ObjectCreate(chartID,"trend line", OBJ_TREND,0,anchorone,high,anchortwo,low);
   ObjectSetInteger(chartID,"trend line",OBJPROP_RAY,0);
   ObjectSetInteger(chartID,"trend line",OBJPROP_COLOR,clrOrangeRed);
   ObjectSetInteger(chartID,"trend line",OBJPROP_WIDTH,3);

   };
   
   
   {long chartID= ChartID();

   //Primary wave
   int highestshift=iHighest(NULL,PERIOD_H1,MODE_HIGH,70,1);
   int lowestshift=iLowest(NULL,PERIOD_H1,MODE_LOW,70,1);
   double high=iHigh(NULL,PERIOD_H1,highestshift);
   double low=iLow(NULL,PERIOD_H1,lowestshift);
   datetime anchorone = iTime(NULL,PERIOD_H1,highestshift);
   datetime anchortwo = iTime(NULL,PERIOD_H1,lowestshift);
   
   ObjectCreate(chartID,"fibo1",OBJ_FIBO,0,anchorone,high,anchortwo,low);
   ObjectSetInteger(chartID,"fibo1",OBJPROP_LEVELCOLOR,clrRoyalBlue);
   ObjectSetInteger(chartID,"fibo1",OBJPROP_COLOR,clrRoyalBlue);
   ObjectSetInteger(chartID,"fibo1",OBJPROP_WIDTH,3);

   };
   
   {long chartID= ChartID();

   //Primary wave
   int highestshift=iHighest(NULL,PERIOD_H4,MODE_HIGH,70,1);
   int lowestshift=iLowest(NULL,PERIOD_H4,MODE_LOW,70,1);
   double high=iHigh(NULL,PERIOD_H4,highestshift);
   double low=iLow(NULL,PERIOD_H4,lowestshift);
   datetime anchorone = iTime(NULL,PERIOD_H4,highestshift);
   datetime anchortwo = iTime(NULL,PERIOD_H4,lowestshift);
   
   ObjectCreate(chartID,"fibo",OBJ_FIBO,0,anchorone,high,anchortwo,low);
   ObjectSetInteger(chartID,"fibo",OBJPROP_LEVELCOLOR,clrDarkOrange);
   ObjectSetInteger(chartID,"fibo",OBJPROP_COLOR,clrDarkOrange);
   ObjectSetInteger(chartID,"fibo",OBJPROP_WIDTH,3);

   };   */
   
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
//+------------------------------------------------------------------+