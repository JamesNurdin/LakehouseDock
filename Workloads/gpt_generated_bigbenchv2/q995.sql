WITH item_ratings AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
store_sales_agg AS (
    SELECT
        ss_store_id,
        ss_item_id,
        SUM(ss_quantity) AS store_quantity,
        SUM(ss_quantity * i_price) AS store_revenue
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    GROUP BY ss_store_id, ss_item_id
),
web_sales_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS web_quantity,
        SUM(ws_quantity * i_price) AS web_revenue
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    GROUP BY ws_item_id
),
store_customers AS (
    SELECT
        ss_store_id,
        COUNT(DISTINCT ss_customer_id) AS distinct_customers
    FROM store_sales
    GROUP BY ss_store_id
)
SELECT
    s.s_store_name,
    i.i_category_name,
    i.i_name,
    COALESCE(ss.store_quantity, 0) AS store_quantity,
    COALESCE(ws.web_quantity, 0) AS web_quantity,
    COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0) AS total_revenue,
    ir.avg_rating,
    ir.review_count,
    sc.distinct_customers
FROM stores s
JOIN store_sales_agg ss ON s.s_store_id = ss.ss_store_id
JOIN items i ON ss.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.ws_item_id
LEFT JOIN item_ratings ir ON i.i_item_id = ir.pr_item_id
LEFT JOIN store_customers sc ON s.s_store_id = sc.ss_store_id
ORDER BY total_revenue DESC
LIMIT 100
