WITH sales_agg AS (
  SELECT
    w.w_warehouse_name AS warehouse_name,
    w.w_state AS state,
    wp.wp_type AS page_type,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_sales_price) AS avg_sales_price
  FROM web_sales ws
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2453650
    AND wp.wp_type IN ('home', 'product')
    AND w.w_state = 'CA'
  GROUP BY w.w_warehouse_name, w.w_state, wp.wp_type
  HAVING SUM(ws.ws_net_profit) > 5000
)
SELECT
  warehouse_name,
  state,
  page_type,
  total_profit,
  total_quantity,
  avg_sales_price,
  RANK() OVER (PARTITION BY page_type ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY page_type, profit_rank
