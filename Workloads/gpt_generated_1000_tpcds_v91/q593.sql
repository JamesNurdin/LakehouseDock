WITH sales_agg AS (
    SELECT
        s.s_store_sk AS store_sk,
        s.s_store_name AS store_name,
        SUM(ss.ss_net_profit) AS total_sales_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
),
returns_agg AS (
    SELECT
        s.s_store_sk AS store_sk,
        s.s_store_name AS store_name,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
),
full_join AS (
    SELECT
        COALESCE(sa.store_sk, ra.store_sk) AS store_sk,
        COALESCE(sa.store_name, ra.store_name) AS store_name,
        COALESCE(sa.total_sales_profit, 0) AS total_sales_profit,
        COALESCE(ra.total_return_loss, 0) AS total_return_loss
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra ON sa.store_sk = ra.store_sk
),
high_stores AS (
    SELECT store_sk FROM sales_agg WHERE total_sales_profit > 20000
    UNION ALL
    SELECT store_sk FROM returns_agg WHERE total_return_loss > 5000
)
SELECT
    fj.store_sk,
    fj.store_name,
    fj.total_sales_profit,
    fj.total_return_loss,
    CASE
        WHEN fj.total_sales_profit > fj.total_return_loss THEN 'Profit'
        WHEN fj.total_sales_profit < fj.total_return_loss THEN 'Loss'
        ELSE 'Break-even'
    END AS profit_status,
    CONCAT('Store-', fj.store_name) AS labeled_store,
    SUBSTRING(fj.store_name, 1, 10) AS short_name,
    REGEXP_EXTRACT(fj.store_name, '(\\d+)', 1) AS extracted_number,
    l.lower_store_name,
    l.store_prefix,
    (SELECT AVG(total_sales_profit) FROM sales_agg) AS avg_sales_profit
FROM full_join fj
CROSS JOIN LATERAL (
    SELECT
        LOWER(fj.store_name) AS lower_store_name,
        REGEXP_EXTRACT(fj.store_name, '^([A-Za-z]+)', 1) AS store_prefix
) AS l
WHERE fj.store_name LIKE '%Store%'
  AND REGEXP_LIKE(fj.store_name, '[0-9]')
  AND fj.store_sk IN (SELECT store_sk FROM high_stores)
ORDER BY profit_status, fj.total_sales_profit DESC
LIMIT 100
