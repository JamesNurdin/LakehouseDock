WITH sales_agg AS (
    SELECT
        s.s_store_name AS store_name,
        'sale' AS transaction_type,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS total_amount,
        CASE
            WHEN SUM(ss.ss_net_paid) > (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2) THEN 'above_avg'
            ELSE 'below_avg'
        END AS performance_flag
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_number_employees > 50
      AND EXISTS (
          SELECT 1
          FROM store_sales ss_check
          WHERE ss_check.ss_store_sk = s.s_store_sk
            AND ss_check.ss_sold_date_sk = d.d_date_sk
            AND ss_check.ss_net_paid > 0
      )
    GROUP BY s.s_store_name, d.d_year
),
returns_agg AS (
    SELECT
        CAST(NULL AS varchar) AS store_name,
        'return' AS transaction_type,
        d.d_year AS year,
        SUM(cr.cr_return_amount) AS total_amount,
        CASE
            WHEN SUM(cr.cr_return_amount) > 1000 THEN 'high'
            ELSE 'low'
        END AS performance_flag
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cr.cr_return_amount > 0
    GROUP BY d.d_year
)
SELECT
    store_name,
    transaction_type,
    year,
    total_amount,
    performance_flag
FROM (
    SELECT store_name, transaction_type, year, total_amount, performance_flag FROM sales_agg
    UNION ALL
    SELECT store_name, transaction_type, year, total_amount, performance_flag FROM returns_agg
) combined
ORDER BY year DESC, total_amount DESC
LIMIT 100
