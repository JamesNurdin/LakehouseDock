WITH returns AS (
  SELECT
    c.c_customer_id,
    ca.ca_city,
    'return' AS metric_type,
    SUM(cr.cr_return_amt_inc_tax) AS amount
  FROM catalog_returns cr
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE w.w_country = 'United States'
    AND sm.sm_type = 'AIR'
  GROUP BY c.c_customer_id, ca.ca_city
),
sales AS (
  SELECT
    c.c_customer_id,
    ca.ca_city,
    'sale' AS metric_type,
    SUM(ws.ws_net_paid_inc_tax) AS amount
  FROM web_sales ws
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE w.w_country = 'United States'
    AND sm.sm_type = 'GROUND'
  GROUP BY c.c_customer_id, ca.ca_city
)
SELECT *
FROM returns
UNION ALL
SELECT *
FROM sales
ORDER BY c_customer_id, metric_type
