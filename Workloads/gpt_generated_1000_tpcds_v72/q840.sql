WITH store_sales_filtered AS (
    SELECT DISTINCT
        c.c_customer_id AS customer_id,
        i.i_item_id      AS item_id,
        d.d_year         AS year
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2020
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_item_sk = ss.ss_item_sk
            AND cr.cr_returned_date_sk = ss.ss_sold_date_sk
      )
),
catalog_sales_filtered AS (
    SELECT DISTINCT
        c.c_customer_id AS customer_id,
        i.i_item_id      AS item_id,
        d.d_year         AS year
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2020
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_order_number = cs.cs_order_number
      )
)
SELECT DISTINCT
    customer_id,
    item_id,
    year
FROM (
    SELECT customer_id, item_id, year FROM store_sales_filtered
    UNION
    SELECT customer_id, item_id, year FROM catalog_sales_filtered
) combined
ORDER BY year DESC, customer_id
LIMIT 100
