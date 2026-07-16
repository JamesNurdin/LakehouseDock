WITH sales AS (
   SELECT ws.ws_sold_date_sk AS sold_date_sk,
          ws.ws_sold_time_sk AS sold_time_sk,
          ws.ws_order_number AS order_number,
          ws.ws_item_sk AS item_sk,
          ws.ws_net_paid,
          ws.ws_net_profit
   FROM web_sales ws
   WHERE ws.ws_sold_date_sk IN (
         SELECT d_date_sk FROM date_dim WHERE d_year = 1902 AND d_quarter_seq = 2
   )
),
returns AS (
   SELECT wr.wr_returned_date_sk AS returned_date_sk,
          wr.wr_returned_time_sk AS returned_time_sk,
          wr.wr_order_number AS order_number,
          wr.wr_item_sk AS item_sk,
          wr.wr_return_amt AS return_amt
   FROM web_returns wr
   WHERE wr.wr_returned_date_sk IN (
         SELECT d_date_sk FROM date_dim WHERE d_year = 1902 AND d_quarter_seq = 2
   )
),
sales_with_returns AS (
   SELECT s.sold_date_sk,
          s.sold_time_sk,
          s.order_number,
          s.item_sk,
          s.ws_net_paid,
          s.ws_net_profit,
          COALESCE(r.return_amt, 0) AS return_amt
   FROM sales s
   LEFT JOIN returns r
     ON s.order_number = r.order_number
    AND s.item_sk = r.item_sk
    AND s.sold_date_sk = r.returned_date_sk
),
 daily_hourly AS (
   SELECT d.d_year,
          d.d_month_seq,
          d.d_dom,
          d.d_date,
          t.t_hour,
          SUM(swr.ws_net_paid) AS total_net_paid,
          SUM(swr.ws_net_profit) AS total_net_profit,
          SUM(swr.return_amt) AS total_return_amt,
          SUM(swr.ws_net_paid) - SUM(swr.return_amt) AS net_sales_after_returns
   FROM sales_with_returns swr
   JOIN date_dim d ON swr.sold_date_sk = d.d_date_sk
   JOIN time_dim t ON swr.sold_time_sk = t.t_time_sk
   WHERE d.d_year = 1902
     AND d.d_following_holiday = 'N'
     AND t.t_shift = 'Evening'
   GROUP BY d.d_year, d.d_month_seq, d.d_dom, d.d_date, t.t_hour
   HAVING SUM(swr.ws_net_paid) > 1000
),
store_closures AS (
   SELECT d.d_month_seq,
          COUNT(s.s_store_sk) AS stores_closed
   FROM store s
   JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
   WHERE d.d_year = 1902
   GROUP BY d.d_month_seq
)
SELECT dh.d_year,
       dh.d_month_seq,
       dh.d_dom,
       dh.d_date,
       dh.t_hour,
       dh.total_net_paid,
       dh.total_net_profit,
       dh.total_return_amt,
       dh.net_sales_after_returns,
       sc.stores_closed,
       AVG(dh.net_sales_after_returns) OVER (PARTITION BY dh.d_year ORDER BY dh.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_7day_avg_net_sales
FROM daily_hourly dh
LEFT JOIN store_closures sc ON dh.d_month_seq = sc.d_month_seq
ORDER BY dh.net_sales_after_returns DESC
LIMIT 100
