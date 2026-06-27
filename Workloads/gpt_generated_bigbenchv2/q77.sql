WITH store_category_sales AS (
    SELECT
        stores.s_store_id,
        stores.s_store_name,
        items.i_category_id,
        items.i_category_name,
        SUM(store_sales.ss_quantity) AS total_store_quantity,
        SUM(store_sales.ss_quantity * items.i_price) AS total_store_revenue
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    JOIN stores ON store_sales.ss_store_id = stores.s_store_id
    GROUP BY
        stores.s_store_id,
        stores.s_store_name,
        items.i_category_id,
        items.i_category_name
),
category_web_sales AS (
    SELECT
        items.i_category_id,
        items.i_category_name,
        SUM(web_sales.ws_quantity) AS total_web_quantity,
        SUM(web_sales.ws_quantity * items.i_price) AS total_web_revenue
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    GROUP BY
        items.i_category_id,
        items.i_category_name
),
category_ratings AS (
    SELECT
        items.i_category_id,
        items.i_category_name,
        AVG(product_reviews.pr_rating) AS avg_rating,
        COUNT(product_reviews.pr_review_id) AS review_count
    FROM product_reviews
    JOIN items ON product_reviews.pr_item_id = items.i_item_id
    GROUP BY
        items.i_category_id,
        items.i_category_name
)
SELECT
    scs.s_store_id,
    scs.s_store_name,
    scs.i_category_id,
    scs.i_category_name,
    scs.total_store_quantity,
    scs.total_store_revenue,
    cw.total_web_quantity,
    cw.total_web_revenue,
    cr.avg_rating,
    cr.review_count
FROM store_category_sales scs
LEFT JOIN category_web_sales cw
    ON scs.i_category_id = cw.i_category_id
LEFT JOIN category_ratings cr
    ON scs.i_category_id = cr.i_category_id
ORDER BY scs.s_store_id, scs.total_store_revenue DESC
