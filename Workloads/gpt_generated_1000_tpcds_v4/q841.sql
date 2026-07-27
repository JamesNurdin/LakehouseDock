WITH base_sales AS (
   SELECT
     d.d_year,
     sm.sm_ship_mode_id,
     ws.ws_net_profit,
     ws.ws_ext_sales_price
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   WHERE
     d.d_year BETWEEN 2000 AND 2002
     AND ca.ca_state IN ('CA', 'TX', 'NY')
     AND sm.sm_contract LIKE '%JkzjqD8MGXLCDa%'
     AND ws.ws_list_price > 50
     AND ws.ws_quantity >= 1
     AND EXISTS (
        SELECT 1 FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
          AND wr.wr_return_amt > 100
          AND wr.wr_returned_date_sk = d.d_date_sk
     )
),
sales_agg AS (
   SELECT
     d_year,
     sm_ship_mode_id,
     COUNT(*) AS orders_cnt,
     SUM(ws_net_profit) AS total_profit,
     AVG(ws_net_profit) AS avg_profit,
     SUM(ws_ext_sales_price) AS total_sales
   FROM base_sales
   GROUP BY d_year, sm_ship_mode_id
),
ranked_sales AS (
   SELECT
     d_year,
     sm_ship_mode_id,
     orders_cnt,
     total_profit,
     avg_profit,
     total_sales,
     ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
   FROM sales_agg
)
SELECT
  d_year,
  sm_ship_mode_id,
  orders_cnt,
  total_profit,
  avg_profit,
  total_sales,
  profit_rank
FROM ranked_sales
WHERE total_profit > 10000
ORDER BY d_year DESC, total_profit DESC
LIMIT 100
