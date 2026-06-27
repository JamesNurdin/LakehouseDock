WITH
    store_sales_agg AS (
        SELECT
            ss_item_id,
            SUM(ss_quantity) AS store_quantity,
            SUM(ss_quantity * i_price) AS store_revenue
        FROM store_sales
        JOIN items ON store_sales.ss_item_id = items.i_item_id
        GROUP BY ss_item_id
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
    rating_agg AS (
        SELECT
            pr_item_id,
            AVG(pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews
        GROUP BY pr_item_id
    ),
    customer_agg AS (
        SELECT
            item_id,
            COUNT(DISTINCT customer_id) AS distinct_customers
        FROM (
            SELECT ss_item_id AS item_id, ss_customer_id AS customer_id
            FROM store_sales
            UNION ALL
            SELECT ws_item_id AS item_id, ws_customer_id AS customer_id
            FROM web_sales
        ) AS combined
        GROUP BY item_id
    )
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    ra.avg_rating,
    ra.review_count,
    ca.distinct_customers
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.ss_item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN rating_agg ra ON i.i_item_id = ra.pr_item_id
LEFT JOIN customer_agg ca ON i.i_item_id = ca.item_id
WHERE i.i_category_name = 'Electronics'
ORDER BY total_revenue DESC
LIMIT 10
