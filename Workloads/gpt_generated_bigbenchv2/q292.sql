WITH
    item_ratings AS (
        SELECT items.i_item_id,
               AVG(product_reviews.pr_rating) AS avg_rating,
               COUNT(*) AS rating_count
        FROM product_reviews
        JOIN items ON product_reviews.pr_item_id = items.i_item_id
        GROUP BY items.i_item_id
    ),
    store_sales_agg AS (
        SELECT store_sales.ss_store_id,
               store_sales.ss_item_id,
               SUM(store_sales.ss_quantity) AS total_quantity,
               SUM(store_sales.ss_quantity * items.i_price) AS total_revenue
        FROM store_sales
        JOIN items ON store_sales.ss_item_id = items.i_item_id
        GROUP BY store_sales.ss_store_id, store_sales.ss_item_id
    ),
    web_sales_agg AS (
        SELECT CAST(NULL AS bigint) AS ss_store_id,
               web_sales.ws_item_id AS ss_item_id,
               SUM(web_sales.ws_quantity) AS total_quantity,
               SUM(web_sales.ws_quantity * items.i_price) AS total_revenue
        FROM web_sales
        JOIN items ON web_sales.ws_item_id = items.i_item_id
        GROUP BY web_sales.ws_item_id
    ),
    combined_sales AS (
        SELECT ss_store_id,
               ss_item_id,
               total_quantity,
               total_revenue
        FROM store_sales_agg
        UNION ALL
        SELECT ss_store_id,
               ss_item_id,
               total_quantity,
               total_revenue
        FROM web_sales_agg
    ),
    sales_by_store_item AS (
        SELECT ss_store_id,
               ss_item_id,
               SUM(total_quantity) AS total_quantity,
               SUM(total_revenue) AS total_revenue
        FROM combined_sales
        GROUP BY ss_store_id, ss_item_id
    )
SELECT
    COALESCE(stores.s_store_name, 'Online') AS store_name,
    items.i_name AS item_name,
    items.i_category_name,
    sales_by_store_item.total_quantity,
    sales_by_store_item.total_revenue,
    COALESCE(item_ratings.avg_rating, 0) AS avg_rating,
    items.i_price,
    items.i_comp_price,
    (items.i_price - items.i_comp_price) AS price_diff
FROM sales_by_store_item
LEFT JOIN stores
    ON sales_by_store_item.ss_store_id = stores.s_store_id
JOIN items
    ON sales_by_store_item.ss_item_id = items.i_item_id
LEFT JOIN item_ratings
    ON items.i_item_id = item_ratings.i_item_id
ORDER BY sales_by_store_item.total_revenue DESC
LIMIT 100
