WITH q1 AS (
  SELECT
    c.c_customer_id,
    s.s_store_name,
    sm.sm_type,
    w.w_warehouse_name,
    SUM(cs.cs_ext_sales_price)        AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price)        AS total_web_sales,
    SUM(sr.sr_return_amt_inc_tax)     AS total_returns,
    (SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price) - SUM(sr.sr_return_amt_inc_tax)) AS net_sales
  FROM catalog_sales cs
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
                     AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                     AND ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE cs.cs_ship_date_sk BETWEEN 2450830 AND 2450886
    AND ws.ws_sold_date_sk BETWEEN 2450830 AND 2450886
    AND w.w_gmt_offset = -5.00
  GROUP BY c.c_customer_id, s.s_store_name, sm.sm_type, w.w_warehouse_name
  HAVING (SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price) - SUM(sr.sr_return_amt_inc_tax)) > 1000
),
q2 AS (
  SELECT
    c.c_customer_id,
    s.s_store_name,
    sm.sm_type,
    w.w_warehouse_name,
    SUM(cs.cs_ext_sales_price)        AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price)        AS total_web_sales,
    SUM(sr.sr_return_amt_inc_tax)     AS total_returns,
    (SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price) - SUM(sr.sr_return_amt_inc_tax)) AS net_sales
  FROM catalog_sales cs
  JOIN customer c ON cs.cs_ship_customer_sk = c.c_customer_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN web_sales ws ON ws.ws_ship_customer_sk = c.c_customer_sk
                     AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                     AND ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE cs.cs_ship_date_sk BETWEEN 2450869 AND 2450899
    AND ws.ws_sold_date_sk BETWEEN 2450869 AND 2450899
    AND w.w_gmt_offset = -6.00
  GROUP BY c.c_customer_id, s.s_store_name, sm.sm_type, w.w_warehouse_name
  HAVING (SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price) - SUM(sr.sr_return_amt_inc_tax)) > 1000
),
combined AS (
  SELECT * FROM q1
  UNION DISTINCT
  SELECT * FROM q2
)
SELECT
  c_customer_id,
  s_store_name,
  sm_type,
  w_warehouse_name,
  total_catalog_sales,
  total_web_sales,
  total_returns,
  net_sales,
  RANK() OVER (PARTITION BY sm_type ORDER BY net_sales DESC) AS sales_rank
FROM combined
WHERE net_sales > 5000
ORDER BY sm_type, sales_rank, net_sales DESC
LIMIT 100
