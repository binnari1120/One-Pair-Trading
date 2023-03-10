//+------------------------------------------------------------------+
//|                         Two Pairs Arbitrage for Udemy_v1.0.0.mq4 |
//|                                             Nomad AlgoTrading Lab|
//|                              https://www.nomadalgotradinglab.com |
//+------------------------------------------------------------------+

// -- Properties --
#property copyright "Nomad AlgoTrading Lab"
#property link      "https://www.nomadalgotradinglab.com"
#property version   "1.0.0"
#property strict

// -- Extern variables --
input string Separator1="========Basic Setting==============";
input int MagicNo=1;
input int Slippage=3;
input bool AreSymbolsNegativelyCorrelated=false;
input string Symbol_1="EURUSD";
input double Symbol_1_Lotsize=0.1;
input double Symbol_1_SpreadLimit=10;
input string Symbol_2="GBPUSD";
input double Symbol_2_Lotsize=0.1;
input double Symbol_2_SpreadLimit=10;
input double AnyOPairProfitToClose=5;
input double ResidualPairProfitToClose=0;
input string Separator2="========Recovery Mode==============";
input bool IsRecoveryModeEnabled=true;
input double AllPairsProfitToClose=0;
input string Separator3="========Daily Target Profit==============";
input double DailyTargetProfit=4.5;

// -- Global variables --
int GV_lastDayOfWeek=DayOfWeek();
double GV_dailyTargetBalance=AccountBalance()+DailyTargetProfit;
bool GV_isDailyTargetProfitLockActive=false;

string GV_oPair_1_comment="Original Pair #1";
string GV_oPair_2_comment="Original Pair #2";
string GV_rPair_comment="Recovery Pair";

// this event function automatically activates
// whenever an E.A. is attached to a chart.
int OnInit()
 { 
  // the main thread checks symbol name validity.
  if(MarketInfo(Symbol_1,MODE_ASK)==0 || MarketInfo(Symbol_2,MODE_ASK)==0)
   {
    Alert("Invalid symbol name!");
    return(INIT_FAILED);
   }
  // the main thread checks lot size validity.
  if(MarketInfo(Symbol_1,MODE_MINLOT)>Symbol_1_Lotsize 
    || MarketInfo(Symbol_2,MODE_MINLOT)>Symbol_2_Lotsize)
   {
    Alert("Invalid lot size!");
    return(INIT_FAILED);
   }
  return(INIT_SUCCEEDED);
 }

// this event function automatically activates
// whenever an E.A. is detached from the chart it runs on.
void OnDeinit(const int reason)
 {
 }

// this event function automatically activates
// whenever there is a tick on the chart.
void OnTick()
 {    
  // -- Local variables --
  int totalPos=GetNumberOfTotalPositions(GV_oPair_1_comment)
                +GetNumberOfTotalPositions(GV_oPair_2_comment)
                +GetNumberOfTotalPositions(GV_rPair_comment);
  
  // [ Step 1 ~ 4 ]
  // if the D.T.P. lock is not active,
  if(GV_isDailyTargetProfitLockActive==false)
   {
    // if there is no position under our E.A.'s control from the trading pool,
    if(totalPos==0)
     {
      // < Step 4: the main thread compares the the account balance             >
      // <         with the target balance of the day (the Daily Target Profit) >
      // if the current account balance is larger than the target balance of the day,
      if(AccountBalance()>GV_dailyTargetBalance) 
       {
        // the main thread activates the D.T.P. lock.
        GV_isDailyTargetProfitLockActive=true;

        // the main thread sends a notification with case number 6.              
        SendMobileNotification(6);

        // the main thread terminates itself so as to ignore the rest codes below.              
        return;
       }
      // < Step 1: the main thread checks the market conditions           >
      // <         to open the two original pairs (the decoy tactic)      >
      // if the market conditions to open the two original pairs are satisfied,  
      if(CheckMarketConditionsToOpenOPairs()==true)
       {
        // the main thread opens the first original pair.
        OpenBuy(Symbol_1,Symbol_1_Lotsize,GV_oPair_1_comment);
        if(AreSymbolsNegativelyCorrelated==false) 
          OpenSell(Symbol_2,Symbol_2_Lotsize,GV_oPair_1_comment);
             
        // if the two symbols are negatively correlated,
        // then the main thread inverts the position for the second symbol.           
        else OpenBuy(Symbol_2,Symbol_2_Lotsize,GV_oPair_1_comment);
        
        // the main thread opens the second original pair.
        OpenSell(Symbol_1,Symbol_1_Lotsize,GV_oPair_2_comment);
        if(AreSymbolsNegativelyCorrelated==false) 
          OpenBuy(Symbol_2,Symbol_2_Lotsize,GV_oPair_2_comment);  
               
        // if the two symbols are negatively correlated,
        // then the main thread inverts the position for the second symbol.           
        else OpenSell(Symbol_2,Symbol_2_Lotsize,GV_oPair_2_comment);

        // the main thread sends a notification with case number 0.              
        SendMobileNotification(0);
       }        
     }
    // [ Step 2 ~ 3 ]
    // if there is a position under our E.A.'s control from the trading pool
    else if(totalPos>0)
     {
      // < Step 2: the main thread checks the market conditions >
      // <         to close one of the two original pairs       >
      // <         when the mean reversion starts               >
      // if there are the first original pair and the second original pair 
      // under our E.A.'s control from the trading pool,   
      if((GetNumberOfTotalPositions(GV_oPair_1_comment)>0) 
        && (GetNumberOfTotalPositions(GV_oPair_2_comment)>0))
       {
        // if the conditions to close the first original pair are satisfied,  
        if(CheckMarketConditionsToCloseOPair(GV_oPair_1_comment,
            AnyOPairProfitToClose)==true)
         {
          // then the main thread closes the first original pair.  
          ClosePair(GV_oPair_1_comment);

          // the main thread sends a notification with case number 1.              
          SendMobileNotification(1);

          // if the main thread will close the residual pair under the normal mode, 
          // then the main thread sends a notification with case number 2. 
          // Or else, the main thread sends a notification with case number 4.               
          if(IsRecoveryModeEnabled==false) SendMobileNotification(2);
          else SendMobileNotification(4);                                    
         }   
        // if the conditions to close the second original pair are satisfied,  
        else if(CheckMarketConditionsToCloseOPair(GV_oPair_2_comment,
            AnyOPairProfitToClose)==true)
         {
          // the main thread closes the second original pair.
          ClosePair(GV_oPair_2_comment);

          // the main thread sends a notification with case number 1.              
          SendMobileNotification(1);

          // if the main thread will close the residual pair under the normal mode, 
          // then the main thread sends a notification with case number 2. 
          // Or else, the main thread sends a notification with case number 4.               
          if(IsRecoveryModeEnabled==false) SendMobileNotification(2);
          else SendMobileNotification(4);                                    
         }
       }       
      // [ Step 3N: under the normal mode ] 
      if(IsRecoveryModeEnabled==false)
       {
        // < Step 3N: the main thread checks the market conditions     >
        // <          to close the residual pair                       >
        // <          when the price discrepancy is disappeared        >
        // <          by the mean reversion                            >  
        // if there is only the first original pair 
        // under our E.A.'s control from the trading pool,   
        // meaning the first original pair is the residual pair, 
        if((GetNumberOfTotalPositions(GV_oPair_1_comment)>0) 
          && (GetNumberOfTotalPositions(GV_oPair_2_comment)==0))       
         {
          // if the conditions to close the first original pair are satisfied,  
          if(CheckMarketConditionsToCloseOPair(GV_oPair_1_comment,
              ResidualPairProfitToClose)==true)
           {
            // the main thread closes the first original pair.   
            ClosePair(GV_oPair_1_comment);

            // the main thread sends a notification with case number 3.              
            SendMobileNotification(3);
           }
         }  
        // if there is only the second original pair 
        // under our E.A.'s control from the trading pool,   
        // meaning the second original pair is the residual pair, 
        if((GetNumberOfTotalPositions(GV_oPair_1_comment)==0) 
          && (GetNumberOfTotalPositions(GV_oPair_2_comment)>0))       
         {
          // if the market conditions to close the second original pair are satisfied,  
          if(CheckMarketConditionsToCloseOPair(GV_oPair_2_comment,
              ResidualPairProfitToClose)==true)
           {
            // the main thread closes the second original pair. 
            ClosePair(GV_oPair_2_comment);

            // the main thread sends a notification with case number 3.              
            SendMobileNotification(3);
           }  
         }
       }  
      // [ Step 3R: under the recovery mode ]  
      else if(IsRecoveryModeEnabled==true)
       {
        // < Step 3R-1: the main thread opens opens the recovery pair, >
        // <            a copy of the residual pair                    >
        // if there is no recovery pair from the trading pool, 
        if(GetNumberOfTotalPositions(GV_rPair_comment)==0)
         {
          // if the first original pair is the residual pair, 
          if((GetNumberOfTotalPositions(GV_oPair_1_comment)>0) 
            && (GetNumberOfTotalPositions(GV_oPair_2_comment)==0))       
           {
            // the main thread opens the recovery pair
            // that is a copy of the first original pair. 
            OpenBuy(Symbol_1,Symbol_1_Lotsize,GV_rPair_comment);
            if(AreSymbolsNegativelyCorrelated==false)
              OpenSell(Symbol_2,Symbol_2_Lotsize,GV_rPair_comment); 
                        
            // if the two symbols are negatively correlated,
            // the main thread inverts the position for the second symbol.        
            else OpenBuy(Symbol_2,Symbol_2_Lotsize,GV_rPair_comment);    
           }
          // if the second original pair is the residual pair, 
          if((GetNumberOfTotalPositions(GV_oPair_1_comment)==0) 
            && (GetNumberOfTotalPositions(GV_oPair_2_comment)>0))       
           {
            // the main thread opens the recovery pair
            // that is a copy of the second original pair.
            OpenSell(Symbol_1,Symbol_1_Lotsize,GV_rPair_comment);
            if(AreSymbolsNegativelyCorrelated==false) 
              OpenBuy(Symbol_2,Symbol_2_Lotsize,GV_rPair_comment);   
                       
            // if the two symbols are negatively correlated,
            // the main thread inverts the position for the second symbol.         
            else OpenSell(Symbol_2,Symbol_2_Lotsize,GV_rPair_comment);    
           } 
         }   
        // < Step 3R-2: the main thread checks the market conditions                >
        // <            to close the residual pair and the recovery pair altogether >
        // <            when the price discrepancy is partially eliminated          >
        // <            by the mean reversion                                       >
        // if there is already a recovery pair from the trading pool, 
        else if(GetNumberOfTotalPositions(GV_rPair_comment)>0)
         {
          // if the conditions to close all pairs are satisfied,  
          if(CheckMarketConditionsToCloseAllPairs(AllPairsProfitToClose)==true)
           {
            // the main thread closes all pairs.   
            ClosePair(GV_rPair_comment);
            ClosePair(GV_oPair_1_comment);
            ClosePair(GV_oPair_2_comment);

            // the main thread sends a notification with case number 5.              
            SendMobileNotification(5);
           }
         }    
       }          
     }  
   }  
  // [ Step 4(additional) ]
  // if the D.T.P lock is active,
  else if(GV_isDailyTargetProfitLockActive==true)
   {
    // < Step 4: the main thread checks a day changes           >
    // <         to reset the target balance and resume trading >
    // if a day has changed,
    if(DayOfWeek()!=GV_lastDayOfWeek)
     {
      // the main thread resets all global variables.
      GV_lastDayOfWeek=DayOfWeek();
      GV_dailyTargetBalance=AccountBalance()+DailyTargetProfit;    
      GV_isDailyTargetProfitLockActive=false;

      // the main thread sends a notification with case number 7.              
      SendMobileNotification(7);
     }
   }
 }
 
// the main thread calculates the number of positions with certain attributes
// under our E.A.'s control from the trading pool.
int GetNumberOfTotalPositions (string comment)
 {
  int cnt=0;
  for(int i=0; i<OrdersTotal(); i++)
   {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
     {
      if(OrderMagicNumber()==MagicNo 
          && OrderComment()==comment
          && OrderType()<=OP_SELL) cnt++;
     }
   }
  return cnt;
 }

// the main thread calculates the net profit of a specific pair
// under our E.A.'s control from the trading pool.
double GetPairNetProfit (string comment)
 { 
  double profit=0;
  for(int i=0; i<OrdersTotal(); i++)
   {
    if(OrderSelect(i,SELECT_BY_POS)==true)
     {
      if(OrderMagicNumber()==MagicNo && OrderComment()==comment) 
        profit=profit+OrderProfit()+OrderCommission()+OrderSwap();
     }   
   }
  return(profit);
 }
  
// the main thread calculates the net profit of all pairs
// under our E.A.'s control from the trading pool.
double GetNetProfit ()
 { 
  double profit=0;
  for(int i=0; i<OrdersTotal(); i++)
   {
    if(OrderSelect(i,SELECT_BY_POS)==true)
     {
      if(OrderMagicNumber()==MagicNo) 
        profit=profit+OrderProfit()+OrderCommission()+OrderSwap();
     }   
   }
  return(profit);
 }

// the main thread checks the market conditions to open the two original pairs.
bool CheckMarketConditionsToOpenOPairs ()
 {
  bool result=false;
  if((Symbol_1_SpreadLimit>MarketInfo(Symbol_1,MODE_SPREAD)) 
  && (Symbol_2_SpreadLimit>MarketInfo(Symbol_2,MODE_SPREAD))) 
    result=true;
  return(result);
 }

// the main thread checks the market conditions to close an original pair. 
bool CheckMarketConditionsToCloseOPair (string comment, double profit)
 {
  bool result=false;
  if(GetPairNetProfit(comment)>profit) result=true;
  return(result);
 }

// the main threads checks the market conditions to close all pairs. 
bool CheckMarketConditionsToCloseAllPairs (double profit)
 {
  bool result=false;
  if(GetNetProfit()>profit) result=true;
  return(result);
 }

// the main thread takes a long position on a symbol.  
void OpenBuy (string symbol, double lotSize, string comment)
 {
  int ticketNo=0;
  while(true)
   {
    Sleep(1);
    ticketNo=OrderSend(symbol,OP_BUY,lotSize,
                       MarketInfo(symbol,MODE_ASK),
                       Slippage,0,0,comment,MagicNo,0,clrBlue);
    if(ticketNo>0) break;
    else Print("Error opening buy order (error code: ",GetLastError(),")"); 
   }  
 }
 
// the main thread takes a short position on a symbol.   
void OpenSell (string symbol, double lotSize, string comment)
 {
  int ticketNo=0;
  while(true)
   {
    Sleep(1);
    ticketNo=OrderSend(symbol,OP_SELL,lotSize,
                       MarketInfo(symbol,MODE_BID),
                       Slippage,0,0,comment,MagicNo,0,clrBlue);
    if(ticketNo>0) break;
    else Print("Error opening sell order (error code: ",GetLastError(),")"); 
   }
 }
 
// the main thread closes positions with certain attributes.  
void ClosePair (string comment)
 {
  bool result=false;
  while(true)
   {
    Sleep(1);
    for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS)==true)
       { 
        if(OrderMagicNumber()==MagicNo && OrderComment()==comment)
         {
          if(OrderType()==OP_BUY) 
            result=OrderClose(OrderTicket(),OrderLots(),
                              MarketInfo(OrderSymbol(),MODE_BID),Slippage,clrRed);
          else if(OrderType()==OP_SELL)
            result=OrderClose(OrderTicket(),OrderLots(),
                              MarketInfo(OrderSymbol(),MODE_ASK),Slippage,clrRed);
          if(result==false) 
            Print("Error closing an order (error code: ",GetLastError(),")"); 
         }
       }         
     }
    if(GetNumberOfTotalPositions(comment)==0) break; 
   } 
 }  
 
// the main thread sends a mobile push message to update you with one of few cases.   
void SendMobileNotification (int type)
 {
  string message="";
  switch(type)
   {
    case 0: message=StringConcatenate("Two original pairs opened",
            " (account number: ",AccountNumber(),")"); break;
    case 1: message=StringConcatenate("One original pair closed in profit",
            " (account number: ",AccountNumber(),")"); break;
    case 2: message=StringConcatenate("Normal mode activated",
            " (account number: ",AccountNumber(),")"); break;
    case 3: message=StringConcatenate("Normal mode deactivated successfully",
            " (account number: ",AccountNumber(),")"); break;
    case 4: message=StringConcatenate("Recovery mode activated",
            " (account number: ",AccountNumber(),")"); break;
    case 5: message=StringConcatenate("Recovery mode deactivated successfully",
            " (account number: ",AccountNumber(),")"); break;
    case 6: message=StringConcatenate("Today's target profit has acheived",
            " - D.T.P lock activated (account number: ",AccountNumber(),")");
            break;
    case 7: message=StringConcatenate("New day started - D.T.P. lock deactivate",
            " (account number: ",AccountNumber(),")"); break;
   }
  SendNotification(message);
 }
 
 