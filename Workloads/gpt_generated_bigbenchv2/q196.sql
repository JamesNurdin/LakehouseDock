WITH
    store_sales_agg AS (
        SELECT
            ss_item_id,
            SUM(ss_quantity) AS total_store_quantity,
            COUNT(*) AS store_transactions
        FROM store_sales
        GROUP BY ss_item_id
    ),
    web_sales_agg AS (
        SELECT
            ws_item_id,
            SUM(ws_quantity) AS total_web_quantity,
            COUNT(*) AS web_transactions
        FROM web_sales
        GROUP BY ws_item_id
    ),
    reviews_agg AS (
        SELECT
            pr_item_id,
            AVG(pr_rating) AS avg_rating,
            COUNT(*) AS review_count,
            MAX(pr_ts) AS latest_review_ts
        FROM product_reviews
        GROUP BY pr_item_id
    ),
    category_customers AS (
        SELECT i.i_category_id,
               i.i_category_name,
               ss.ss_customer_id AS customer_id
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        UNION
        SELECT i.i_category_id,
               i.i_category_name,
               ws.ws_customer_id AS customer_id
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
    ),
    category_customers_agg AS (
        SELECT i_category_id,
               i_category_name,
               COUNT(DISTINCT customer_id) AS distinct_customers
        FROM category_customers
        GROUP BY i_category_id, i_category_name
    )
SELECT
    i.i_category_id,
    i.i_category_name,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    COALESCE(SUM(ss.total_store_quantity), 0) + COALESCE(SUM(ws.total_web_quantity), 0) AS total_quantity_sold,
    COALESCE(SUM(ss.total_store_quantity), 0) AS total_store_quantity,
    COALESCE(SUM(ws.total_web_quantity), 0) AS total_web_quantity,
    COALESCE(SUM(ss.total_store_quantity * i.i_price), 0) + COALESCE(SUM(ws.total_web_quantity * i.i_price), 0) AS total_revenue,
    cc.distinct_customers,
    AVG(i.i_price) AS avg_item_price,
    AVG(COALESCE(r.avg_rating, 0)) AS avg_item_rating,
    SUM(COALESCE(r.review_count, 0)) AS total_reviews,
    MAX(r.latest_review_ts) AS most_recent_review_ts
FROM items i
LEFT JOIN store_sales_agg ss ON ss.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg ws ON ws.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.pr_item_id = i.i_item_id
LEFT JOIN category_customers_agg cc ON cc.i_category_id = i.i_category_id
GROUP BY
    i.i_category_id,
    i.i_category_name,
    cc.distinct_customers
ORDER BY total_quantity_sold DESC
LIMIT 10
