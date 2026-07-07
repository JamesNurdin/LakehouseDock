WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_quantity_store,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue_store,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers_store
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_quantity_web,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue_web,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers_web
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    i.i_item_id,
    i.i_name,
    COALESCE(ssa.total_quantity_store, 0) AS total_quantity_store,
    COALESCE(wsa.total_quantity_web, 0) AS total_quantity_web,
    COALESCE(ssa.total_quantity_store, 0) + COALESCE(wsa.total_quantity_web, 0) AS total_quantity,
    COALESCE(ssa.total_revenue_store, 0) + COALESCE(wsa.total_revenue_web, 0) AS total_revenue,
    COALESCE(ssa.distinct_customers_store, 0) AS distinct_customers_store,
    COALESCE(wsa.distinct_customers_web, 0) AS distinct_customers_web,
    rag.avg_sentiment,
    rag.review_count
FROM items i
LEFT JOIN store_sales_agg ssa ON i.i_item_id = ssa.ss_item_id
LEFT JOIN web_sales_agg wsa ON i.i_item_id = wsa.ws_item_id
LEFT JOIN reviews_agg rag ON i.i_item_id = rag.pr_item_id
WHERE i.i_price > 0
ORDER BY total_quantity DESC
LIMIT 100
