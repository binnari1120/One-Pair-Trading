//+------------------------------------------------------------------+
//|                                   Average Pair Spread_v1.0.0.mq4 |
//|                                                  Nomad Quant Lab |
//|                                        https://nomadquantlab.com |
//+------------------------------------------------------------------+
#property copyright   "www.nomadquantlab.com"
#property link        "https://nomadquantlab.com"
#property strict

#property indicator_separate_window
#property indicator_buffers 7
#property indicator_color1 Red
#property indicator_color2 Yellow
#property indicator_color3 LightSeaGreen
#property indicator_color4 LightSeaGreen
#property indicator_color5 Yellow
#property indicator_color6 LightSeaGreen
#property indicator_color7 LightSeaGreen

input string Symbol_1="GBPUSDe";
input string Symbol_2="EURUSDe";
input int    BandsPeriod=100;      
input double BandsDeviations_1=0.05; 
input double BandsDeviations_2=1.96; 
input double BandsDeviations_3=2.58;

//--- buffers
int GV_unifiedNumberOfBars=0;

double GA_symbol_1_closes[], GA_symbol_2_closes[];
double GA_symbol_1_and_2_closeGaps[];

double GA_middleBand[];
double GA_standardDeviations[];
double GA_upperBand_1[];
double GA_upperBand_2[];
double GA_upperBand_3[];

double GA_lowerBand_1[];
double GA_lowerBand_2[];
double GA_lowerBand_3[];

int OnInit(void)
  {
   if(MarketInfo(Symbol_1,MODE_ASK)==0 || MarketInfo(Symbol_2,MODE_ASK)==0)
    {
     Alert("Invalid symbol name: please check syntax on the symbols.");
     return(INIT_FAILED);
    }    
   GV_unifiedNumberOfBars=MathMin(iBars(Symbol_1,PERIOD_CURRENT),iBars(Symbol_2,PERIOD_CURRENT));

   /*if(GV_unifiedNumberOfBars<1)
    {
     Alert("Chart timeframe changed: please attach the indicator to the chart again.");
     return(INIT_FAILED);
    }*/   
   if(BandsPeriod<=0)
    {
     Alert("Invalid BandsPeriod count: BandsPeriod should be larger than or equal to 1.");
     return(INIT_FAILED);
    }   
   
   ArrayResize(GA_symbol_1_closes,GV_unifiedNumberOfBars);
   ArrayResize(GA_symbol_2_closes,GV_unifiedNumberOfBars);
   ArrayResize(GA_symbol_1_and_2_closeGaps,GV_unifiedNumberOfBars);   
   ArrayResize(GA_middleBand,GV_unifiedNumberOfBars);
   ArrayResize(GA_standardDeviations,GV_unifiedNumberOfBars);
   ArrayResize(GA_upperBand_1,GV_unifiedNumberOfBars);
   ArrayResize(GA_upperBand_2,GV_unifiedNumberOfBars);
   ArrayResize(GA_upperBand_3,GV_unifiedNumberOfBars);
   ArrayResize(GA_lowerBand_1,GV_unifiedNumberOfBars);
   ArrayResize(GA_lowerBand_2,GV_unifiedNumberOfBars);
   ArrayResize(GA_lowerBand_3,GV_unifiedNumberOfBars);
   
   ArrayInitialize(GA_symbol_1_closes,EMPTY_VALUE);
   ArrayInitialize(GA_symbol_2_closes,EMPTY_VALUE);
   ArrayInitialize(GA_symbol_1_and_2_closeGaps,EMPTY_VALUE);
   ArrayInitialize(GA_middleBand,EMPTY_VALUE);
   ArrayInitialize(GA_standardDeviations,EMPTY_VALUE);
   ArrayInitialize(GA_upperBand_1,EMPTY_VALUE);
   ArrayInitialize(GA_upperBand_2,EMPTY_VALUE);
   ArrayInitialize(GA_upperBand_3,EMPTY_VALUE);
   ArrayInitialize(GA_lowerBand_1,EMPTY_VALUE);
   ArrayInitialize(GA_lowerBand_2,EMPTY_VALUE);
   ArrayInitialize(GA_lowerBand_3,EMPTY_VALUE);


   IndicatorBuffers(8);
   IndicatorDigits(Digits);

   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,GA_symbol_1_and_2_closeGaps);
   SetIndexLabel(0,"Medians");

   //SetIndexStyle(1,DRAW_LINE);
   //SetIndexBuffer(1,GA_middleBand);
   //SetIndexLabel(1,"Bands SMA");

   SetIndexStyle(1,DRAW_LINE);
   SetIndexBuffer(1,GA_upperBand_1);
   SetIndexLabel(1,"UpperBand_1");

   SetIndexStyle(2,DRAW_LINE);
   SetIndexBuffer(2,GA_upperBand_2);
   SetIndexLabel(2,"UpperBand_2");

   SetIndexStyle(3,DRAW_LINE);
   SetIndexBuffer(3,GA_upperBand_3);
   SetIndexLabel(3,"UpperBand_3");

   SetIndexStyle(4,DRAW_LINE);
   SetIndexBuffer(4,GA_lowerBand_1);
   SetIndexLabel(4,"LowerBand_1");

   SetIndexStyle(5,DRAW_LINE);
   SetIndexBuffer(5,GA_lowerBand_2);
   SetIndexLabel(5,"LowerBand_2");

   SetIndexStyle(6,DRAW_LINE);
   SetIndexBuffer(6,GA_lowerBand_3);
   SetIndexLabel(6,"LowerBand_3");

   if(BandsPeriod<=0)
    {
     Print("Wrong input parameter Bands Period=",BandsPeriod);
     return(INIT_FAILED);
    }

   return(INIT_SUCCEEDED);
  }
 
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {   
   bool isBarChanged=false;
   
   if(rates_total-prev_calculated>0) isBarChanged=true;
   if(isBarChanged==true)
    {
     for(int i=0; i<GV_unifiedNumberOfBars; i++)
      {
       GA_symbol_1_closes[i]=iClose(Symbol_1,PERIOD_CURRENT,i);
       GA_symbol_2_closes[i]=iClose(Symbol_2,PERIOD_CURRENT,i);
       GA_symbol_1_and_2_closeGaps[i]=(GA_symbol_1_closes[i]-GA_symbol_2_closes[i]);
      }
     for(int i=0; i<GV_unifiedNumberOfBars; i++)
      {
       GA_middleBand[i]=GetArrayAverage(GA_symbol_1_and_2_closeGaps,BandsPeriod,i);
       GA_standardDeviations[i]=GetArrayStandardDeviation(GA_symbol_1_and_2_closeGaps,GA_middleBand[i],BandsPeriod,i);
       GA_upperBand_1[i]=GA_middleBand[i]+BandsDeviations_1*GA_standardDeviations[i];
       GA_lowerBand_1[i]=GA_middleBand[i]-BandsDeviations_1*GA_standardDeviations[i];
       GA_upperBand_2[i]=GA_middleBand[i]+BandsDeviations_2*GA_standardDeviations[i];
       GA_lowerBand_2[i]=GA_middleBand[i]-BandsDeviations_2*GA_standardDeviations[i];
       GA_upperBand_3[i]=GA_middleBand[i]+BandsDeviations_3*GA_standardDeviations[i];
       GA_lowerBand_3[i]=GA_middleBand[i]-BandsDeviations_3*GA_standardDeviations[i];
      }
    }
   else
    {
     GA_symbol_1_closes[0]=iClose(Symbol_1,PERIOD_CURRENT,0);
     GA_symbol_2_closes[0]=iClose(Symbol_2,PERIOD_CURRENT,0);
     GA_symbol_1_and_2_closeGaps[0]=(GA_symbol_1_closes[0]-GA_symbol_2_closes[0]);    

     GA_middleBand[0]=GetArrayAverage(GA_symbol_1_and_2_closeGaps,BandsPeriod,0);
     GA_standardDeviations[0]=GetArrayStandardDeviation(GA_symbol_1_and_2_closeGaps,GA_middleBand[0],BandsPeriod,0);
     GA_upperBand_1[0]=GA_middleBand[0]+BandsDeviations_1*GA_standardDeviations[0];
     GA_lowerBand_1[0]=GA_middleBand[0]-BandsDeviations_1*GA_standardDeviations[0];
     GA_upperBand_2[0]=GA_middleBand[0]+BandsDeviations_2*GA_standardDeviations[0];
     GA_lowerBand_2[0]=GA_middleBand[0]-BandsDeviations_2*GA_standardDeviations[0];
     GA_upperBand_3[0]=GA_middleBand[0]+BandsDeviations_3*GA_standardDeviations[0];
     GA_lowerBand_3[0]=GA_middleBand[0]-BandsDeviations_3*GA_standardDeviations[0];
    }  
   return(rates_total);
  }

double GetArrayAverage (double &array[], int averagePeriod, int position)
 {
  double sum=0;
  double result=0;
  
  if(ArraySize(array)>=position+averagePeriod)
   {
    for(int i=0; i<averagePeriod; i++) sum+=array[position+i];
   }  
  result=sum/averagePeriod;
  return(result);
 }

double GetArrayStandardDeviation (double &array[], double maPrice, int averagePeriod, int position)
 {
  double squaredSum=0;
  double result=0;
  
  if(ArraySize(array)>=position+averagePeriod)
   {
    for(int i=0; i<averagePeriod; i++) squaredSum+=MathPow(array[position+i]-maPrice,2);
   }  
  result=MathSqrt(squaredSum/averagePeriod);
  return(result);
 }