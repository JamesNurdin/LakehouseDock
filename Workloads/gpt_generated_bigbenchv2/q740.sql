WITH
    store_sales_agg AS (
        SELECT
            i.i_item_id,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS store_revenue,
            COUNT(DISTINCT ss.ss_customer_id) AS store_customers
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    web_sales_agg AS (
        SELECT
            i.i_item_id,
            SUM(ws.ws_quantity) AS web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS web_revenue,
            COUNT(DISTINCT ws.ws_customer_id) AS web_customers
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    rating_agg AS (
        SELECT
            pr.pr_item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    )
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(ss_agg.store_quantity, 0) + COALESCE(ws_agg.web_quantity, 0) AS total_quantity,
    COALESCE(ss_agg.store_revenue, 0) + COALESCE(ws_agg.web_revenue, 0) AS total_revenue,
    COALESCE(ss_agg.store_customers, 0) + COALESCE(ws_agg.web_customers, 0) AS total_customers,
    r_agg.avg_rating,
    r_agg.review_count
FROM items i
LEFT JOIN store_sales_agg ss_agg ON i.i_item_id = ss_agg.i_item_id
LEFT JOIN web_sales_agg ws_agg ON i.i_item_id = ws_agg.i_item_id
LEFT JOIN rating_agg r_agg ON i.i_item_id = r_agg.pr_item_id
WHERE r_agg.avg_rating >= 4
ORDER BY total_revenue DESC
LIMIT 20
