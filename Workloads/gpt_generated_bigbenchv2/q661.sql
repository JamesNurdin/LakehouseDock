WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_transaction_id) AS store_transactions
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
store_customer_counts AS (
    SELECT
        ss.ss_store_id,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    GROUP BY ss.ss_store_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_transaction_id) AS web_transactions
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
item_review_agg AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    s.s_store_name,
    i.i_category_name,
    i.i_name,
    scc.distinct_customers,
    COALESCE(ssa.store_quantity, 0) AS store_quantity,
    COALESCE(wsa.web_quantity, 0) AS web_quantity,
    COALESCE(ira.avg_rating, 0) AS avg_rating,
    COALESCE(ira.review_count, 0) AS review_count,
    (COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0)) * i.i_price AS total_revenue_estimate
FROM store_sales_agg ssa
JOIN stores s ON ssa.ss_store_id = s.s_store_id
JOIN items i ON ssa.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wsa ON i.i_item_id = wsa.ws_item_id
LEFT JOIN item_review_agg ira ON i.i_item_id = ira.i_item_id
JOIN store_customer_counts scc ON ssa.ss_store_id = scc.ss_store_id
ORDER BY total_revenue_estimate DESC
LIMIT 100
