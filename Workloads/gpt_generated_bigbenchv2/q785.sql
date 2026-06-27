WITH
    store_sales_agg AS (
        SELECT
            ss_store_id,
            i_category_id,
            i_category_name,
            SUM(ss_quantity) AS store_quantity,
            COUNT(DISTINCT ss_customer_id) AS distinct_customers
        FROM store_sales
        JOIN items ON store_sales.ss_item_id = items.i_item_id
        GROUP BY ss_store_id, i_category_id, i_category_name
    ),
    store_customer_sales AS (
        SELECT
            ss_store_id,
            i_category_id,
            i_category_name,
            ss_customer_id,
            SUM(ss_quantity) AS cust_quantity
        FROM store_sales
        JOIN items ON store_sales.ss_item_id = items.i_item_id
        GROUP BY ss_store_id, i_category_id, i_category_name, ss_customer_id
    ),
    top_customer_per_category AS (
        SELECT
            ss_store_id,
            i_category_id,
            i_category_name,
            ss_customer_id,
            cust_quantity
        FROM (
            SELECT
                ss_store_id,
                i_category_id,
                i_category_name,
                ss_customer_id,
                cust_quantity,
                ROW_NUMBER() OVER (PARTITION BY ss_store_id, i_category_id ORDER BY cust_quantity DESC) AS rn
            FROM store_customer_sales
        )
        WHERE rn = 1
    ),
    top_customer_name AS (
        SELECT
            top_customer_per_category.ss_store_id,
            top_customer_per_category.i_category_id,
            top_customer_per_category.i_category_name,
            customers.c_name AS top_customer_name,
            top_customer_per_category.cust_quantity AS top_customer_quantity
        FROM top_customer_per_category
        JOIN customers ON top_customer_per_category.ss_customer_id = customers.c_customer_id
    ),
    web_sales_agg AS (
        SELECT
            CAST(NULL AS bigint) AS ss_store_id,
            i_category_id,
            i_category_name,
            SUM(ws_quantity) AS web_quantity
        FROM web_sales
        JOIN items ON web_sales.ws_item_id = items.i_item_id
        GROUP BY i_category_id, i_category_name
    ),
    rating_agg AS (
        SELECT
            i_category_id,
            i_category_name,
            AVG(pr_rating) AS avg_rating,
            COUNT(pr_review_id) AS review_count
        FROM product_reviews
        JOIN items ON product_reviews.pr_item_id = items.i_item_id
        GROUP BY i_category_id, i_category_name
    )
SELECT
    COALESCE(stores.s_store_name, 'Online') AS store_name,
    COALESCE(store_sales_agg.i_category_id, web_sales_agg.i_category_id) AS category_id,
    COALESCE(store_sales_agg.i_category_name, web_sales_agg.i_category_name) AS category_name,
    COALESCE(store_sales_agg.store_quantity, 0) AS total_store_quantity,
    COALESCE(web_sales_agg.web_quantity, 0) AS total_web_quantity,
    store_sales_agg.distinct_customers,
    rating_agg.avg_rating,
    rating_agg.review_count,
    top_customer_name.top_customer_name,
    top_customer_name.top_customer_quantity
FROM store_sales_agg
FULL OUTER JOIN web_sales_agg
    ON store_sales_agg.i_category_id = web_sales_agg.i_category_id
LEFT JOIN rating_agg
    ON COALESCE(store_sales_agg.i_category_id, web_sales_agg.i_category_id) = rating_agg.i_category_id
LEFT JOIN stores
    ON store_sales_agg.ss_store_id = stores.s_store_id
LEFT JOIN top_customer_name
    ON store_sales_agg.ss_store_id = top_customer_name.ss_store_id
    AND store_sales_agg.i_category_id = top_customer_name.i_category_id
ORDER BY (COALESCE(store_sales_agg.store_quantity, 0) + COALESCE(web_sales_agg.web_quantity, 0)) DESC
LIMIT 100
