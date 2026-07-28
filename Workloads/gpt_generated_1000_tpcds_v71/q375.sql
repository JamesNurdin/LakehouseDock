WITH catalog_data AS (
   SELECT
      d.d_date AS sales_date,
      c.c_customer_id,
      cs.cs_ext_sales_price AS sales_amount,
      'Catalog' AS channel,
      ROW_NUMBER() OVER (PARTITION BY d.d_date ORDER BY cs.cs_ext_sales_price DESC) AS sales_rank
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE EXISTS (
       SELECT 1 FROM store_returns sr
       WHERE sr.sr_customer_sk = c.c_customer_sk
   )
     AND d.d_year = 2002
),
web_data AS (
   SELECT
      d.d_date AS sales_date,
      c.c_customer_id,
      ws.ws_ext_sales_price AS sales_amount,
      'Web' AS channel,
      ROW_NUMBER() OVER (PARTITION BY d.d_date ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE EXISTS (
       SELECT 1 FROM store_returns sr
       WHERE sr.sr_customer_sk = c.c_customer_sk
   )
     AND d.d_year = 2002
)
SELECT sales_date,
       c_customer_id,
       sales_amount,
       channel,
       sales_rank
FROM catalog_data
UNION ALL
SELECT sales_date,
       c_customer_id,
       sales_amount,
       channel,
       sales_rank
FROM web_data
ORDER BY sales_date DESC, channel, sales_rank
LIMIT 100
