//+------------------------------------------------------------------+
//|                                                        empty.mq4 |
//|                                                               MP |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "MP"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
long chartID=ChartID();
datetime anchorpointone, anchorpoint0, anchorpointtwo;
void CreateTrendLines(string name,double price1, double price2,string text,color clr,int style)
  {  
   ObjectCreate(chartID,name,OBJ_TREND,0,anchorpointone,price1,anchorpointtwo,price2);
   ObjectSetInteger(chartID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chartID,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chartID,name,OBJPROP_RAY,0);
   ObjectSetInteger(chartID,name,OBJPROP_WIDTH,2);
   ObjectSetString(chartID,name,OBJPROP_TEXT,text);    
  }
bool CheckTrend(int timeframe,double pricerange,int period,int shift)
{     
   double close[];ArrayResize(close,period,0); ArrayInitialize(close,1);
   double open[];ArrayResize(open,period,0); ArrayInitialize(open,1);
   double low[];ArrayResize(low,period,0); ArrayInitialize(low,1);
   double high[];ArrayResize(high,period,0); ArrayInitialize(high,1);
   double openclosespread[];ArrayResize(openclosespread,period,0); ArrayInitialize(openclosespread,1);
   double averageopenclose[];ArrayResize(averageopenclose,period,0); ArrayInitialize(averageopenclose,1);
   double totalaverageopenclose=0;
   bool bullish=0;
   int bars=1;
   int countbars=0;
   int firstanchorbar=0;
   int secondanchorbar=0;
      for(int i=shift-1;i<period-1;i++)
      {
      close[i]=iClose(NULL,timeframe,i);
      open[i]=iOpen(NULL,timeframe,i);
      low[i]=iLow(NULL,timeframe,i);
      high[i]=iHigh(NULL,timeframe,i);
      
       
      if(close[i]>open[i])
      {openclosespread[i]=close[i]-open[i]; 
      averageopenclose[i]=open[i]+openclosespread[i]/2;
      bullish=1;}
      
      if(close[i]<open[i])
      {openclosespread[i]=open[i]-close[i]; 
      averageopenclose[i]=close[i]+openclosespread[i]/2;
      bullish=0;}
      
      
      Print(i);
      if(i==shift)anchorpointone=iTime(NULL,timeframe,i);
      else anchorpointone=iTime(NULL,timeframe,firstanchorbar);
      
      secondanchorbar=firstanchorbar;
      if(openclosespread[i]<pricerange)
         {
         secondanchorbar++;
         countbars++;
         totalaverageopenclose=totalaverageopenclose+averageopenclose[i];
         Print("continue");
         continue;
         }
      
      else {
      
      Print("more than pricerange - i=",i);
      //i=i+countbars; Print(i);
      anchorpoint0=iTime(NULL,timeframe,countbars);

      CreateTrendLines("trendline "+IntegerToString(countbars),close[countbars],open[i],"trendline",clrDarkViolet,0);
      }
      
      double slope=averageopenclose[i]/bars;   
 
      }

   
   

return(false);
}








bool CheckTrend2(int timeframe,double pricerange,int period,int shift)
{  
   int totalbarstocheck=period+shift;   
   double close[];ArrayResize(close,totalbarstocheck,0); ArrayInitialize(close,1);
   double open[];ArrayResize(open,totalbarstocheck,0); ArrayInitialize(open,1);
   double low[];ArrayResize(low,totalbarstocheck,0); ArrayInitialize(low,1);
   double high[];ArrayResize(high,totalbarstocheck,0); ArrayInitialize(high,1);
   double openclosespread[];ArrayResize(openclosespread,totalbarstocheck,0); ArrayInitialize(openclosespread,1);
   double averageopenclose[];ArrayResize(averageopenclose,totalbarstocheck,0); ArrayInitialize(averageopenclose,1);
   double totalaverageopenclose=0;
   bool bullish=0;
   int countbars=0;
   int firstanchorbar=shift;
   int secondanchorbar=shift;
   int i=shift;
   anchorpointone=iTime(NULL,timeframe,firstanchorbar);
   anchorpointtwo=iTime(NULL,timeframe,secondanchorbar);  
     
      
   for(i=shift;i<totalbarstocheck-1;i++)
      {
      close[i]=iClose(NULL,timeframe,i);
      open[i]=iOpen(NULL,timeframe,i);
      low[i]=iLow(NULL,timeframe,i);
      high[i]=iHigh(NULL,timeframe,i);
       
      if(close[i]>open[i])
      {openclosespread[i]=close[i]-open[i]; 
      averageopenclose[i]=open[i]+openclosespread[i]/2;
      bullish=1;}
      
      if(close[i]<open[i])
      {openclosespread[i]=open[i]-close[i]; 
      averageopenclose[i]=close[i]+openclosespread[i]/2;
      bullish=0;}
      
      
      if(openclosespread[i]<pricerange)
         {
         secondanchorbar++;
         Print("continue");
         continue;
         }
      
      else {
      //firstanchorbar==shift+firstanchorbar;
      Print("more than pricerange - i=",i);
      anchorpointtwo=iTime(NULL,timeframe,secondanchorbar);
      CreateTrendLines("trendline "+IntegerToString(secondanchorbar),close[firstanchorbar],open[secondanchorbar],"trendline",clrDarkViolet,0); 
      anchorpointone=anchorpointtwo;
      firstanchorbar=secondanchorbar;
      }
      

 
      }

   
   

return(false);
}









//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
CheckTrend2(PERIOD_H1,0.00100,20,3);
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
