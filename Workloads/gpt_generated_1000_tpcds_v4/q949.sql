WITH sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        CAST('sales' AS varchar) AS activity_type,
        SUM(cs.cs_net_paid) AS total_amount,
        NULL AS store_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cs.cs_quantity > 0
    GROUP BY d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        CAST('returns' AS varchar) AS activity_type,
        SUM(sr.sr_net_loss) AS total_amount,
        s.s_store_name AS store_name
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND sr.sr_store_credit > 0
    GROUP BY d.d_year, d.d_month_seq, s.s_store_name
)
SELECT year, month_seq, activity_type, total_amount, store_name
FROM sales_agg
UNION ALL
SELECT year, month_seq, activity_type, total_amount, store_name
FROM returns_agg
ORDER BY year, month_seq, activity_type
LIMIT 100
