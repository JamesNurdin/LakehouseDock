WITH
    store_sales_agg AS (
        SELECT
            ss_item_id,
            SUM(ss_quantity) AS store_quantity,
            COUNT(DISTINCT ss_customer_id) AS store_customers
        FROM store_sales
        GROUP BY ss_item_id
    ),
    web_sales_agg AS (
        SELECT
            ws_item_id,
            SUM(ws_quantity) AS web_quantity,
            COUNT(DISTINCT ws_customer_id) AS web_customers
        FROM web_sales
        GROUP BY ws_item_id
    ),
    sales_agg AS (
        SELECT
            i.i_item_id,
            COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
            COALESCE(ss.store_customers, 0) + COALESCE(ws.web_customers, 0) AS distinct_customers
        FROM items i
        LEFT JOIN store_sales_agg ss ON ss.ss_item_id = i.i_item_id
        LEFT JOIN web_sales_agg ws ON ws.ws_item_id = i.i_item_id
    ),
    rating_agg AS (
        SELECT
            pr_item_id,
            AVG(pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews
        GROUP BY pr_item_id
    )
SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(s.total_quantity) AS category_total_quantity,
    AVG(r.avg_rating) AS category_avg_rating,
    SUM(s.distinct_customers) AS category_distinct_customers,
    COUNT(DISTINCT i.i_item_id) AS distinct_items
FROM items i
LEFT JOIN sales_agg s ON s.i_item_id = i.i_item_id
LEFT JOIN rating_agg r ON r.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY category_total_quantity DESC
LIMIT 10
