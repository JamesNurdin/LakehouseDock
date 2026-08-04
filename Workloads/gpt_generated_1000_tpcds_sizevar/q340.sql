WITH
cs_filtered AS (
  SELECT cs.cs_order_number,
         cs.cs_ext_ship_cost,
         cs.cs_net_paid,
         cs.cs_net_profit,
         d.d_year,
         sm.sm_type,
         w.w_state,
         p.p_promo_name
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_year = 2001
    AND cs.cs_ext_ship_cost > 1000
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
    AND w.w_country = 'United States'
),
ws_filtered AS (
  SELECT ws.ws_order_number,
         ws.ws_quantity,
         ws.ws_net_paid,
         d2.d_year,
         we.web_state
  FROM web_sales ws
  JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  WHERE d2.d_year = 2001
    AND ws.ws_quantity >= 5
    AND we.web_state = 'CA'
    AND ws.ws_net_paid > 500
),
order_intersection AS (
  SELECT cs_order_number AS order_number FROM cs_filtered
  INTERSECT
  SELECT ws_order_number FROM ws_filtered
),
order_exclusion AS (
  SELECT cs_order_number FROM cs_filtered
  EXCEPT
  SELECT ws_order_number FROM ws_filtered
),
joined_all AS (
  SELECT
    cs.cs_order_number,
    cs.cs_ext_ship_cost,
    cs.cs_net_paid,
    cs.cs_net_profit,
    d.d_year,
    sm.sm_type,
    w.w_state,
    p.p_promo_name,
    ws.ws_quantity,
    ws.ws_net_paid AS ws_net_paid,
    wr.wr_return_amt,
    we.web_state
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  JOIN web_site we ON we.web_site_sk = ws.ws_web_site_sk
  WHERE cs.cs_order_number IN (SELECT order_number FROM order_intersection)
    AND d.d_year = 2001
    AND cs.cs_ext_ship_cost > 1000
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
    AND w.w_country = 'United States'
    AND ws.ws_quantity >= 5
    AND we.web_state = 'CA'
    AND ws.ws_net_paid > 500
)
SELECT
  d_year,
  sm_type,
  w_state,
  p_promo_name,
  COUNT(DISTINCT cs_order_number) AS intersect_order_cnt,
  SUM(cs_net_paid) AS total_cs_net_paid,
  SUM(ws_net_paid) AS total_ws_net_paid,
  SUM(wr_return_amt) AS total_return_amount,
  AVG(cs_ext_ship_cost) AS avg_cs_ship_cost,
  MIN(cs_net_profit) AS min_cs_profit,
  MAX(ws_quantity) AS max_ws_quantity
FROM joined_all
GROUP BY d_year, sm_type, w_state, p_promo_name
ORDER BY total_cs_net_paid DESC
LIMIT 100
