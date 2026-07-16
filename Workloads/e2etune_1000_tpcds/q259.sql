WITH ship_agg AS (
  SELECT
    ca.ca_state AS ship_state,
    ca.ca_city AS ship_city,
    w.w_warehouse_name AS warehouse_name,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt
  FROM web_sales ws
  JOIN customer_address ca
    ON ws.ws_ship_addr_sk = ca.ca_address_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE ws.ws_net_profit > 0
    AND ca.ca_zip LIKE '8%'
    AND w.w_state = ca.ca_state
  GROUP BY ca.ca_state, ca.ca_city, w.w_warehouse_name
)
SELECT
  ship_state,
  ship_city,
  warehouse_name,
  total_profit,
  total_sales,
  avg_discount,
  order_cnt,
  city_rank
FROM (
  SELECT
    ship_state,
    ship_city,
    warehouse_name,
    total_profit,
    total_sales,
    avg_discount,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY ship_state ORDER BY total_profit DESC) AS city_rank
  FROM ship_agg
) t
WHERE city_rank <= 3
ORDER BY ship_state, city_rank
