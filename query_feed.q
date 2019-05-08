/query_feed.q

//connect to AWS gateway 
h: hopen 2001;

/f: {select avg_price:avg price, open: first price, high:max price, low: min price, close: last price, max_mavg: max 10 mavg price by date,sym  from trade where sym in x} 
f1: {select avg_big:avg bid, avg_ask: avg ask,  high_bid:max bid, low_bid: min bid, high_ask:max ask, low_ask: min ask  by date,sym  from quote where sym in x} 

.z.ts: {s:1?`AAPL`AIG`AMD`DELL`DOW`GOOG`HPQ`IBM`INTC`MSFT`ORCL`PEP`PRU`SBUX`TXN;
		 h (f1;s)}

\t 1000


