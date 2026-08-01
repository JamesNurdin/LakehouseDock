WITH sales_agg AS (
    SELECT
        d.d_date AS transaction_date,
        s.s_store_name AS store_name,
        'sales' AS transaction_type,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_count,
        (SELECT COUNT(*) FROM store) AS total_store_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND s.s_market_desc LIKE '%modern%'
      AND EXISTS (
          SELECT 1
          FROM store_sales ss2
          WHERE ss2.ss_store_sk = s.s_store_sk
            AND ss2.ss_net_paid > 1000
      )
    GROUP BY GROUPING SETS (
        (d.d_date, s.s_store_name),
        (d.d_date),
        (s.s_store_name),
        ()
    )
),
returns_agg AS (
    SELECT
        d.d_date AS transaction_date,
        CAST(NULL AS varchar) AS store_name,
        'returns' AS transaction_type,
        SUM(cr.cr_return_amount) AS total_net_paid,
        SUM(cr.cr_net_loss) AS total_profit,
        COUNT(*) AS txn_count,
        (SELECT COUNT(*) FROM store) AS total_store_count
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND cr.cr_return_quantity > 0
    GROUP BY GROUPING SETS (
        (d.d_date),
        ()
    )
)
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM returns_agg
LIMIT 100
