WITH
  sales_data AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      sm.sm_ship_mode_sk,
      sm.sm_ship_mode_id,
      cp.cp_catalog_page_sk,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_ext_tax) AS total_tax,
      SUM(cs.cs_ext_discount_amt) AS total_discount,
      SUM(cs.cs_net_paid) AS total_net_paid,
      COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
      COALESCE(SUM(cr.cr_return_tax), 0) AS total_return_tax
    FROM catalog_sales cs
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
      AND cr.cr_item_sk = cs.cs_item_sk
    WHERE cs.cs_quantity > 1
      AND cp.cp_department = 'Sports'
      AND sm.sm_contract = 'fop0bcSd91J26IVpR'
      AND cs.cs_sold_date_sk BETWEEN 2450905 AND 2450997
    GROUP BY
      c.c_customer_sk,
      c.c_customer_id,
      sm.sm_ship_mode_sk,
      sm.sm_ship_mode_id,
      cp.cp_catalog_page_sk
  ),
  web_data AS (
    SELECT
      c.c_customer_sk,
      sm.sm_ship_mode_sk,
      SUM(ws.ws_ext_sales_price) AS web_sales,
      SUM(ws.ws_ext_tax) AS web_tax
    FROM web_sales ws
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_sales_price > 50
      AND ws.ws_warehouse_sk = 1
      AND ws.ws_sold_date_sk BETWEEN 2450905 AND 2450997
    GROUP BY
      c.c_customer_sk,
      sm.sm_ship_mode_sk
  )
SELECT
  sd.c_customer_id,
  sd.sm_ship_mode_id,
  sd.total_sales,
  COALESCE(wd.web_sales, 0) AS web_sales,
  sd.total_return_amount,
  (sd.total_sales - COALESCE(wd.web_sales, 0) - sd.total_return_amount) AS net_total,
  RANK() OVER (ORDER BY (sd.total_sales - COALESCE(wd.web_sales, 0) - sd.total_return_amount) DESC) AS sales_rank
FROM sales_data sd
LEFT JOIN web_data wd
  ON sd.c_customer_sk = wd.c_customer_sk
  AND sd.sm_ship_mode_sk = wd.sm_ship_mode_sk
ORDER BY sales_rank
LIMIT 100
