WITH sales_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        'sales' AS metric,
        SUM(ss.ss_net_profit) AS amount,
        CASE WHEN SUM(ss.ss_net_profit) >= 10000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, d.d_year
),
returns_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        'returns' AS metric,
        SUM(sr.sr_net_loss) AS amount,
        CASE WHEN SUM(sr.sr_net_loss) >= 5000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, d.d_year
)
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM returns_agg
ORDER BY s_store_id, d_year, metric
