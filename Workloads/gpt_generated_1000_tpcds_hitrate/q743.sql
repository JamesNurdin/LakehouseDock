/* goal: Compare monthly profit performance of store and web channels for the year 2001, rank profits within each channel, and enrich each month with transaction counts and total quantity sold. The result is limited to the first five months, cross‑joined with a small month list, and filtered to states with at least one store in CA. */
WITH store_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
),
combined AS (
    SELECT
        year,
        month,
        total_store_profit AS profit,
        'store' AS channel
    FROM store_sales_agg
    UNION ALL
    SELECT
        year,
        month,
        total_web_profit AS profit,
        'web' AS channel
    FROM web_sales_agg
)
SELECT
    c.year,
    c.month,
    c.channel,
    c.profit,
    CASE WHEN c.profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_sign,
    ROW_NUMBER() OVER (PARTITION BY c.channel ORDER BY c.profit DESC) AS profit_rank,
    (
        SELECT COUNT(*)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = c.year AND d2.d_month_seq = c.month
    ) AS store_txn_count,
    (
        SELECT SUM(ss3.ss_quantity)
        FROM store_sales ss3
        JOIN date_dim d3 ON ss3.ss_sold_date_sk = d3.d_date_sk
        WHERE d3.d_year = c.year AND d3.d_month_seq = c.month
    ) AS total_quantity_sold
FROM combined c
CROSS JOIN (
    SELECT d_month_seq
    FROM date_dim
    WHERE d_year = 2001 AND d_month_seq BETWEEN 1 AND 5
) dm
WHERE c.month = dm.d_month_seq
  AND EXISTS (
        SELECT 1
        FROM store s
        WHERE s.s_state = 'CA'
        LIMIT 1
    )
ORDER BY c.year, c.month, c.channel
LIMIT 100
