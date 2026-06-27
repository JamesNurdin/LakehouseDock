WITH store_agg AS (
    SELECT
        ss_store_id,
        COUNT(DISTINCT ss_transaction_id) AS transaction_count,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_quantity) AS avg_quantity_per_transaction
    FROM store_sales
    GROUP BY ss_store_id
),
store_rank AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        sa.transaction_count,
        sa.total_quantity,
        sa.avg_quantity_per_transaction,
        ROW_NUMBER() OVER (ORDER BY sa.total_quantity DESC) AS store_rank
    FROM stores s
    JOIN store_agg sa
        ON s.s_store_id = sa.ss_store_id
)
SELECT
    s_store_id,
    s_store_name,
    transaction_count,
    total_quantity,
    avg_quantity_per_transaction,
    store_rank
FROM store_rank
ORDER BY store_rank
LIMIT 10
