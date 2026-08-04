WITH
cat_raw AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_warehouse_sk,
    cs.cs_bill_addr_sk,
    cs.cs_sales_price,
    cs.cs_ext_sales_price,
    cs.cs_quantity,
    cs.cs_catalog_page_sk,
    cr.cr_return_amount,
    cr.cr_return_quantity
  FROM catalog_sales cs
  FULL OUTER JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
  WHERE cs.cs_quantity > 1
    AND cs.cs_sales_price BETWEEN 50 AND 200
    AND cs.cs_warehouse_sk IN (1, 2)
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
),
cat_enriched AS (
  SELECT
    cr.*, 
    cp.cp_department,
    cp.cp_description,
    ca.ca_state,
    w.w_warehouse_name
  FROM cat_raw cr
  LEFT JOIN catalog_page cp
    ON cr.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN customer_address ca
    ON cr.cs_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN warehouse w
    ON cr.cs_warehouse_sk = w.w_warehouse_sk
),
web_raw AS (
  SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_warehouse_sk,
    ws.ws_bill_addr_sk,
    ws.ws_sales_price,
    ws.ws_ext_sales_price,
    ws.ws_quantity,
    wr.wr_return_amt,
    wr.wr_return_quantity
  FROM web_sales ws
  LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
  WHERE ws.ws_quantity > 1
    AND ws.ws_sales_price >= 50
    AND ws.ws_warehouse_sk = 1
    AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
),
web_enriched AS (
  SELECT
    wr.*, 
    ca.ca_state,
    w.w_warehouse_name
  FROM web_raw wr
  LEFT JOIN customer_address ca
    ON wr.ws_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN warehouse w
    ON wr.ws_warehouse_sk = w.w_warehouse_sk
),
cat_exclusive AS (
  SELECT cs_order_number FROM cat_enriched
  EXCEPT
  SELECT ws_order_number FROM web_enriched
)
SELECT
  dept,
  warehouse_name,
  state,
  COUNT(DISTINCT order_number) AS num_orders,
  SUM(sales_amount) AS total_sales,
  SUM(return_amount) AS total_returns,
  AVG(sales_price) AS avg_sales_price,
  MAX(return_amount) AS max_return,
  ROW_NUMBER() OVER (ORDER BY SUM(sales_amount) DESC) AS rn
FROM (
  SELECT
    cp_department AS dept,
    w_warehouse_name AS warehouse_name,
    ca_state AS state,
    cs_order_number AS order_number,
    cs_ext_sales_price AS sales_amount,
    COALESCE(cr_return_amount, 0) AS return_amount,
    cs_sales_price AS sales_price,
    CASE WHEN cr_return_amount > 0 THEN 'Returned' ELSE 'NotReturned' END AS return_flag
  FROM cat_enriched
  WHERE cs_order_number IN (SELECT cs_order_number FROM cat_exclusive)

  UNION ALL

  SELECT
    'Web' AS dept,
    w_warehouse_name,
    ca_state,
    ws_order_number,
    ws_ext_sales_price,
    COALESCE(wr_return_amt, 0),
    ws_sales_price,
    CASE WHEN wr_return_amt > 0 THEN 'Returned' ELSE 'NotReturned' END
  FROM web_enriched
) sub
WHERE state = 'CA'
GROUP BY dept, warehouse_name, state
HAVING COUNT(DISTINCT order_number) > 5
ORDER BY total_sales DESC
LIMIT 100
