WITH store_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name
)
SELECT
    s_store_name,
    total_quantity
FROM store_agg
ORDER BY total_quantity DESC
LIMIT 10
