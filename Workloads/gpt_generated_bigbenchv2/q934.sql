WITH monthly_sales AS (
    SELECT
        ss.ss_store_id,
        date_trunc('month', CAST(ss.ss_ts AS timestamp)) AS month,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_id, date_trunc('month', CAST(ss.ss_ts AS timestamp))
)
SELECT
    s.s_store_name,
    ms.month,
    ms.total_quantity,
    RANK() OVER (PARTITION BY ms.month ORDER BY ms.total_quantity DESC) AS store_monthly_rank
FROM monthly_sales ms
JOIN stores s
    ON ms.ss_store_id = s.s_store_id
WHERE ms.total_quantity > 0
ORDER BY ms.month DESC, store_monthly_rank
LIMIT 50
