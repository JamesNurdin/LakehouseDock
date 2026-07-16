SELECT ws.ws_item_sk, SUM(wr.wr_return_amt) AS total_return_amount FROM web_sales ws JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk WHERE ws.ws_sold_date_sk = 2450956 GROUP BY ws.ws_item_sk
