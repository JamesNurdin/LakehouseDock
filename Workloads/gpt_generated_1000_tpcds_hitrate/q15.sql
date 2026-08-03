WITH cs_sales AS (
  SELECT
    w.w_warehouse_id AS warehouse_id,
    w.w_city AS city,
    w.w_state AS state,
    ca.ca_state AS cust_state,
    cs.cs_ext_sales_price AS sales_amount,
    cs.cs_order_number AS order_number
  FROM catalog_sales cs
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE
    REGEXP_LIKE(ca.ca_state, '^M.*')
    AND ca.ca_zip LIKE '3%'
),
ws_sales AS (
  SELECT
    w.w_warehouse_id AS warehouse_id,
    w.w_city AS city,
    w.w_state AS state,
    ca.ca_state AS cust_state,
    ws.ws_ext_sales_price AS sales_amount,
    ws.ws_order_number AS order_number
  FROM web_sales ws
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE
    REGEXP_LIKE(ca.ca_state, '^M.*')
    AND ca.ca_zip LIKE '3%'
)
SELECT
  warehouse_id,
  city,
  state,
  cust_state,
  COUNT(DISTINCT order_number) AS num_orders,
  SUM(sales_amount) AS total_sales,
  REGEXP_EXTRACT(cust_state, '([A-Z])') AS first_state_letter
FROM (
  SELECT * FROM cs_sales
  UNION ALL
  SELECT * FROM ws_sales
) s
GROUP BY
  warehouse_id,
  city,
  state,
  cust_state,
  REGEXP_EXTRACT(cust_state, '([A-Z])')
HAVING
  SUM(sales_amount) > 10000
ORDER BY
  total_sales DESC
LIMIT 100
