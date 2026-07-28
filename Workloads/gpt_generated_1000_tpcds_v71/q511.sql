WITH sales_filtered AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_paid_inc_ship,
    ws.ws_ext_tax,
    ws.ws_ship_mode_sk,
    ws.ws_warehouse_sk,
    ws.ws_sold_date_sk,
    ws.ws_sold_time_sk,
    ws.ws_ship_hdemo_sk,
    ws.ws_ship_addr_sk,
    ws.ws_item_sk,
    CASE WHEN ws.ws_ext_tax > 100 THEN 'HighTax' ELSE 'LowTax' END AS tax_category,
    CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
    sm.sm_code,
    sm.sm_carrier
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year = 2001
    AND regexp_like(ca.ca_city, '^[A-Z][a-z]+$')
    AND ca.ca_state LIKE 'C%'
    AND sm.sm_carrier LIKE '%CAR%'
),
agg AS (
  SELECT
    sm_code,
    city_state,
    tax_category,
    SUM(ws_net_paid_inc_ship) AS total_net_paid,
    COUNT(*) AS sales_cnt
  FROM sales_filtered sf
  WHERE NOT EXISTS (
    SELECT 1 FROM web_returns wr
    WHERE wr.wr_order_number = sf.ws_order_number
  )
  GROUP BY sm_code, city_state, tax_category
  HAVING SUM(ws_net_paid_inc_ship) > 1000
)
SELECT
  sm_code,
  city_state,
  tax_category,
  total_net_paid,
  sales_cnt,
  ROW_NUMBER() OVER (PARTITION BY sm_code ORDER BY total_net_paid DESC) AS rn
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
