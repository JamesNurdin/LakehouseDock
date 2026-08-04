/*
Goal: Identify high‑value catalog sales from the year 2001, categorize the catalog page description using regex and string functions, list the associated customer's full name, compare each customer's total web‑sales net paid, and filter the results with set operations (INTERSECT and EXCEPT) while sampling the catalog_sales table.
*/
WITH
  cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)   -- sample ~10% of rows
  ),
  filtered_cs AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_bill_customer_sk,
      cs.cs_ext_sales_price,
      cs.cs_catalog_page_sk,
      cp.cp_description,
      c.c_first_name,
      c.c_last_name
    FROM cs_sample cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(cp.cp_description, '[A-Z]{3}')
  ),
  ws_agg AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_net_paid) AS total_ws_paid
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_bill_customer_sk
  ),
  intersect_orders AS (
    SELECT cs.cs_order_number
    FROM filtered_cs cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    INTERSECT
    SELECT ws.ws_order_number
    FROM web_sales ws
    JOIN date_dim d2
      ON ws.ws_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
  ),
  except_orders AS (
    SELECT cs.cs_order_number
    FROM filtered_cs cs
    EXCEPT
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
  )
SELECT
  f.cs_order_number,
  f.cs_ext_sales_price,
  substring(cp.cp_description, 1, 10) AS desc_prefix,
  CASE WHEN regexp_like(cp.cp_description, '^.*sale.*$') THEN 'Sale' ELSE 'Other' END AS desc_category,
  concat(f.c_first_name, ' ', f.c_last_name) AS customer_name,
  (
    SELECT SUM(ws.ws_net_paid)
    FROM web_sales ws
    WHERE ws.ws_bill_customer_sk = f.cs_bill_customer_sk
  ) AS customer_ws_total,
  wa.total_ws_paid
FROM filtered_cs f
JOIN catalog_page cp
  ON f.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ws_agg wa
  ON wa.ws_bill_customer_sk = f.cs_bill_customer_sk
WHERE f.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
  AND f.cs_order_number NOT IN (SELECT cs_order_number FROM except_orders)
ORDER BY f.cs_ext_sales_price DESC
LIMIT 100
