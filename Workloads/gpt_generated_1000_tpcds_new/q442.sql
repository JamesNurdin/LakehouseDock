WITH catalog_sales_agg AS (
  SELECT d.d_year AS year,
         'catalog' AS channel,
         SUM(DISTINCT cs.cs_net_paid) AS total_net_paid,
         COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE d.d_year BETWEEN 2001 AND 2002
    AND cp.cp_catalog_number IN (
        SELECT cp2.cp_catalog_number
        FROM catalog_page cp2
        WHERE cp2.cp_department = 'Sports'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_refunded_customer_sk = cs.cs_bill_customer_sk
          AND cr.cr_order_number = cs.cs_order_number
    )
  GROUP BY d.d_year
),
store_sales_agg AS (
  SELECT d.d_year AS year,
         'store' AS channel,
         SUM(DISTINCT ss.ss_net_paid) AS total_net_paid,
         COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  WHERE d.d_year BETWEEN 2001 AND 2002
    AND ss.ss_quantity > 1
    AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_customer_sk = ss.ss_customer_sk
          AND sr.sr_ticket_number = ss.ss_ticket_number
    )
  GROUP BY d.d_year
)
SELECT year,
       channel,
       total_net_paid,
       distinct_customers
FROM catalog_sales_agg
UNION
SELECT year,
       channel,
       total_net_paid,
       distinct_customers
FROM store_sales_agg
ORDER BY year, channel
LIMIT 100
