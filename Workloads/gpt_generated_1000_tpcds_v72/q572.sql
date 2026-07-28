WITH joined_data AS (
   SELECT
      i.i_category,
      i.i_item_id,
      c.c_customer_id,
      t.t_hour AS sale_hour,
      rt.t_hour AS return_hour,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
      sr.sr_return_quantity,
      sr.sr_return_amt
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
   JOIN time_dim rt ON sr.sr_return_time_sk = rt.t_time_sk
   WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
     AND w.w_county = 'Bronx County'
     AND i.i_wholesale_cost > 1.00
     AND rt.t_hour BETWEEN 8 AND 17
     AND EXISTS (
         SELECT 1 FROM reason r
         WHERE r.r_reason_sk = sr.sr_reason_sk
           AND r.r_reason_desc LIKE '%defect%'
     )
),
agg_data AS (
   SELECT
      i_category,
      sale_hour,
      profit_flag,
      SUM(ws_ext_sales_price) AS total_sales,
      SUM(ws_net_profit) AS total_profit,
      COUNT(*) AS txn_count
   FROM joined_data
   GROUP BY ROLLUP (i_category, sale_hour, profit_flag)
   HAVING SUM(ws_ext_sales_price) > 1000
)
SELECT
   i_category,
   sale_hour,
   profit_flag,
   total_sales,
   total_profit,
   txn_count,
   ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS sales_rank,
   CASE
       WHEN total_profit > 0 THEN 'Positive'
       ELSE 'NegativeOrZero'
   END AS profit_status
FROM agg_data
ORDER BY total_sales DESC
LIMIT 100
