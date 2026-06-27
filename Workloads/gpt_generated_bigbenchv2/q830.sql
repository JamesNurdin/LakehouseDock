WITH
    store_sales_agg AS (
        SELECT
            ss_item_id,
            ss_store_id,
            SUM(ss_quantity) AS total_store_qty,
            COUNT(DISTINCT ss_customer_id) AS distinct_store_customers
        FROM store_sales
        GROUP BY ss_item_id, ss_store_id
    ),
    web_sales_agg AS (
        SELECT
            ws_item_id,
            SUM(ws_quantity) AS total_web_qty,
            COUNT(DISTINCT ws_customer_id) AS distinct_web_customers
        FROM web_sales
        GROUP BY ws_item_id
    ),
    reviews_agg AS (
        SELECT
            pr_item_id,
            COUNT(*) AS review_count,
            AVG(pr_rating) AS avg_rating
        FROM product_reviews
        WHERE pr_rating >= 4
        GROUP BY pr_item_id
    )
SELECT
    i.i_category_name,
    s.s_store_name,
    i.i_name,
    i.i_price,
    COALESCE(ss.total_store_qty, 0) AS store_quantity,
    COALESCE(ws.total_web_qty, 0) AS web_quantity,
    COALESCE(ss.distinct_store_customers, 0) + COALESCE(ws.distinct_web_customers, 0) AS total_distinct_customers,
    COALESCE(r.review_count, 0) AS review_count,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    (COALESCE(ss.total_store_qty, 0) + COALESCE(ws.total_web_qty, 0)) * i.i_price AS total_revenue
FROM items i
LEFT JOIN store_sales_agg ss ON ss.ss_item_id = i.i_item_id
LEFT JOIN stores s ON s.s_store_id = ss.ss_store_id
LEFT JOIN web_sales_agg ws ON ws.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.pr_item_id = i.i_item_id
WHERE i.i_category_name IS NOT NULL
ORDER BY total_revenue DESC
LIMIT 100
