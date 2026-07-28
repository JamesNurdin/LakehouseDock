WITH catalog_customer_sales AS (
  SELECT
    c.c_customer_id,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
    COUNT(*) AS order_count
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year = 2001
    AND d.d_holiday = 'N'
    AND EXISTS (
      SELECT 1
      FROM ship_mode sm2
      WHERE sm2.sm_ship_mode_sk = cs.cs_ship_mode_sk
        AND sm2.sm_type = 'AIR'
    )
  GROUP BY c.c_customer_id
),
web_customer_sales AS (
  SELECT
    c.c_customer_id,
    SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales,
    COUNT(*) AS order_count
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year = 2001
    AND d.d_holiday = 'N'
    AND EXISTS (
      SELECT 1
      FROM ship_mode sm2
      WHERE sm2.sm_ship_mode_sk = ws.ws_ship_mode_sk
        AND sm2.sm_type = 'AIR'
    )
  GROUP BY c.c_customer_id
)
SELECT
  c_customer_id,
  total_sales,
  order_count,
  'catalog' AS source
FROM catalog_customer_sales
UNION ALL
SELECT
  c_customer_id,
  total_sales,
  order_count,
  'web' AS source
FROM web_customer_sales
ORDER BY total_sales DESC
LIMIT 100
