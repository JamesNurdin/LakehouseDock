WITH store_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        sum(ss.ss_quantity) AS total_quantity,
        count(*) AS total_transactions,
        count(distinct ss.ss_item_id) AS distinct_items,
        avg(ss.ss_quantity) AS avg_quantity_per_tx
    FROM store_sales ss
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name
)
SELECT
    s_store_id,
    s_store_name,
    total_quantity,
    total_transactions,
    distinct_items,
    avg_quantity_per_tx
FROM store_agg
ORDER BY total_quantity DESC
LIMIT 10
