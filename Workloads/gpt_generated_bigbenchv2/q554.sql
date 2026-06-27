WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
item_ratings AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_name,
    i.i_name,
    i.i_category_name,
    COALESCE(ssa.total_store_quantity, 0) AS store_quantity,
    COALESCE(ssa.total_store_revenue, 0) AS store_revenue,
    COALESCE(wsa.total_web_quantity, 0) AS web_quantity,
    COALESCE(wsa.total_web_revenue, 0) AS web_revenue,
    COALESCE(ssa.distinct_store_customers, 0) + COALESCE(wsa.distinct_web_customers, 0) AS total_distinct_customers,
    ir.avg_rating,
    ir.review_count
FROM items i
LEFT JOIN store_sales_agg ssa ON ssa.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wsa ON wsa.ws_item_id = i.i_item_id
LEFT JOIN item_ratings ir ON ir.pr_item_id = i.i_item_id
LEFT JOIN stores s ON s.s_store_id = ssa.ss_store_id
WHERE i.i_price > 20
  AND (ir.avg_rating IS NULL OR ir.avg_rating >= 4)
ORDER BY store_revenue DESC
LIMIT 10
