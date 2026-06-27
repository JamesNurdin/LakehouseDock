WITH categories AS (
    SELECT DISTINCT i_category_id, i_category_name
    FROM items
),
store_agg AS (
    SELECT
        items.i_category_id,
        items.i_category_name,
        SUM(store_sales.ss_quantity) AS store_quantity,
        SUM(store_sales.ss_quantity * items.i_price) AS store_revenue
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    GROUP BY items.i_category_id, items.i_category_name
),
web_agg AS (
    SELECT
        items.i_category_id,
        items.i_category_name,
        SUM(web_sales.ws_quantity) AS web_quantity,
        SUM(web_sales.ws_quantity * items.i_price) AS web_revenue
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    GROUP BY items.i_category_id, items.i_category_name
),
reviews_agg AS (
    SELECT
        items.i_category_id,
        items.i_category_name,
        AVG(product_reviews.pr_rating) AS avg_rating
    FROM product_reviews
    JOIN items ON product_reviews.pr_item_id = items.i_item_id
    GROUP BY items.i_category_id, items.i_category_name
),
customers_agg AS (
    SELECT
        cat.i_category_id,
        cat.i_category_name,
        COUNT(DISTINCT cat.c_customer_id) AS total_customers
    FROM (
        SELECT
            store_sales.ss_customer_id AS c_customer_id,
            items.i_category_id,
            items.i_category_name
        FROM store_sales
        JOIN items ON store_sales.ss_item_id = items.i_item_id
        UNION ALL
        SELECT
            web_sales.ws_customer_id AS c_customer_id,
            items.i_category_id,
            items.i_category_name
        FROM web_sales
        JOIN items ON web_sales.ws_item_id = items.i_item_id
    ) AS cat
    GROUP BY cat.i_category_id, cat.i_category_name
)
SELECT
    cat.i_category_id,
    cat.i_category_name,
    COALESCE(store_agg.store_quantity, 0) AS store_quantity,
    COALESCE(store_agg.store_revenue, 0.00) AS store_revenue,
    COALESCE(web_agg.web_quantity, 0) AS web_quantity,
    COALESCE(web_agg.web_revenue, 0.00) AS web_revenue,
    reviews_agg.avg_rating,
    COALESCE(customers_agg.total_customers, 0) AS total_customers
FROM categories AS cat
LEFT JOIN store_agg ON cat.i_category_id = store_agg.i_category_id
LEFT JOIN web_agg ON cat.i_category_id = web_agg.i_category_id
LEFT JOIN reviews_agg ON cat.i_category_id = reviews_agg.i_category_id
LEFT JOIN customers_agg ON cat.i_category_id = customers_agg.i_category_id
ORDER BY cat.i_category_id
