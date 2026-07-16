WITH sales_by_warehouse AS (
  SELECT
    w.w_warehouse_name,
    w.w_state,
    ws.ws_sold_date_sk AS sold_date_sk,
    SUM(ws.ws_net_paid) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws.ws_order_number) AS orders_cnt
  FROM web_sales ws
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2453650
    AND w.w_state IN ('CA', 'TX', 'NY')
    AND ws.ws_quantity > 0
    AND ws.ws_coupon_amt > 0
    AND ws.ws_ext_discount_amt > 0
  GROUP BY w.w_warehouse_name, w.w_state, ws.ws_sold_date_sk
  HAVING SUM(ws.ws_quantity) > 100
)
SELECT
  w_warehouse_name,
  w_state,
  sold_date_sk,
  total_sales,
  total_profit,
  total_quantity,
  avg_discount,
  orders_cnt,
  RANK() OVER (PARTITION BY w_state ORDER BY total_profit DESC) AS profit_rank_state,
  RANK() OVER (ORDER BY total_sales DESC) AS sales_rank_global
FROM sales_by_warehouse
WHERE total_sales > 10000
ORDER BY profit_rank_state, sold_date_sk
LIMIT 200
