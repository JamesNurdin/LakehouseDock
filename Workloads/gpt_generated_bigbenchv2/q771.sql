WITH transaction_metrics AS (
    SELECT
        ss.ss_transaction_id,
        ss.ss_customer_id,
        ss.ss_store_id,
        ss.ss_quantity,
        ss.ss_quantity * i.i_price AS revenue,
        ss.ss_quantity * (i.i_price - i.i_comp_price) AS price_diff
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
),
customer_store_agg AS (
    SELECT
        tm.ss_customer_id,
        tm.ss_store_id,
        SUM(tm.revenue) AS total_revenue,
        SUM(tm.price_diff) AS total_price_diff,
        SUM(tm.ss_quantity) AS total_quantity,
        COUNT(DISTINCT tm.ss_transaction_id) AS transaction_count
    FROM transaction_metrics tm
    GROUP BY tm.ss_customer_id, tm.ss_store_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    cs.ss_store_id,
    cs.total_revenue,
    cs.total_price_diff,
    cs.total_quantity,
    cs.transaction_count,
    ROW_NUMBER() OVER (PARTITION BY cs.ss_store_id ORDER BY cs.total_revenue DESC) AS revenue_rank_in_store
FROM customer_store_agg cs
JOIN customers c
    ON cs.ss_customer_id = c.c_customer_id
ORDER BY cs.total_revenue DESC
LIMIT 100
