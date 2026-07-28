WITH sales_agg AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_sold_date_sk,
        d.d_year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_ext_discount_amt > 1000
      AND d.d_year = 2001
    GROUP BY ss.ss_customer_sk, ss.ss_sold_date_sk, d.d_year
)
SELECT
    c.c_customer_id,
    d.d_date,
    cp.cp_catalog_page_number,
    i.inv_quantity_on_hand,
    sa.total_net_paid,
    RANK() OVER (PARTITION BY d.d_year ORDER BY sa.total_net_paid DESC) AS sales_rank,
    CASE WHEN sa.total_discount > 5000 THEN 'HIGH' ELSE 'NORMAL' END AS discount_category
FROM sales_agg sa
JOIN customer c ON sa.ss_customer_sk = c.c_customer_sk
JOIN date_dim d ON sa.ss_sold_date_sk = d.d_date_sk
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
WHERE cp.cp_department = 'DEPARTMENT'
  AND i.inv_quantity_on_hand > 0
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = c.c_customer_sk
          AND ss2.ss_ext_discount_amt > 2000
    )
ORDER BY d.d_year, sales_rank
LIMIT 100
