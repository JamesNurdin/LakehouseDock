WITH store_sales_agg AS (
    SELECT
        store_sales.ss_item_id AS i_item_id,
        SUM(store_sales.ss_quantity) AS store_quantity,
        SUM(store_sales.ss_quantity * items.i_price) AS store_revenue,
        COUNT(DISTINCT store_sales.ss_customer_id) AS store_unique_customers
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    GROUP BY store_sales.ss_item_id
),
web_sales_agg AS (
    SELECT
        web_sales.ws_item_id AS i_item_id,
        SUM(web_sales.ws_quantity) AS web_quantity,
        SUM(web_sales.ws_quantity * items.i_price) AS web_revenue,
        COUNT(DISTINCT web_sales.ws_customer_id) AS web_unique_customers
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    GROUP BY web_sales.ws_item_id
),
reviews_agg AS (
    SELECT
        product_reviews.pr_item_id AS i_item_id,
        AVG(product_reviews.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY product_reviews.pr_item_id
)
SELECT
    items.i_item_id,
    items.i_name,
    items.i_category_name,
    COALESCE(store_sales_agg.store_quantity, 0) AS total_store_quantity,
    COALESCE(web_sales_agg.web_quantity, 0) AS total_web_quantity,
    COALESCE(store_sales_agg.store_quantity, 0) + COALESCE(web_sales_agg.web_quantity, 0) AS total_quantity,
    COALESCE(store_sales_agg.store_revenue, 0) AS total_store_revenue,
    COALESCE(web_sales_agg.web_revenue, 0) AS total_web_revenue,
    COALESCE(store_sales_agg.store_revenue, 0) + COALESCE(web_sales_agg.web_revenue, 0) AS total_revenue,
    COALESCE(store_sales_agg.store_unique_customers, 0) AS store_unique_customers,
    COALESCE(web_sales_agg.web_unique_customers, 0) AS web_unique_customers,
    COALESCE(store_sales_agg.store_unique_customers, 0) + COALESCE(web_sales_agg.web_unique_customers, 0) AS total_unique_customers,
    reviews_agg.avg_rating,
    reviews_agg.review_count
FROM items
LEFT JOIN store_sales_agg ON items.i_item_id = store_sales_agg.i_item_id
LEFT JOIN web_sales_agg   ON items.i_item_id = web_sales_agg.i_item_id
LEFT JOIN reviews_agg     ON items.i_item_id = reviews_agg.i_item_id
ORDER BY total_revenue DESC
LIMIT 10
