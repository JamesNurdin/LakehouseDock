WITH
    store_category_sales AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            s.s_store_id,
            SUM(ss.ss_quantity) AS store_quantity
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        GROUP BY i.i_category_id, i.i_category_name, s.s_store_id
    ),
    top_store_per_category AS (
        SELECT
            i_category_id,
            i_category_name,
            s_store_id,
            store_quantity,
            ROW_NUMBER() OVER (PARTITION BY i_category_id ORDER BY store_quantity DESC) AS rn
        FROM store_category_sales
    ),
    category_instore_sales AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ss.ss_quantity) AS total_instore_quantity,
            COUNT(DISTINCT i.i_item_id) AS distinct_items
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    category_online_sales AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity) AS total_online_quantity
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    category_ratings AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            AVG(pr.pr_rating) AS avg_rating
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    category_prices AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            AVG(i.i_price) AS avg_price
        FROM items i
        GROUP BY i.i_category_id, i.i_category_name
    )
SELECT
    ci.i_category_id,
    ci.i_category_name,
    ci.total_instore_quantity,
    co.total_online_quantity,
    cr.avg_rating,
    cp.avg_price,
    ci.distinct_items,
    s.s_store_name AS top_store_name,
    ts.store_quantity AS top_store_quantity
FROM category_instore_sales ci
LEFT JOIN category_online_sales co
    ON ci.i_category_id = co.i_category_id
    AND ci.i_category_name = co.i_category_name
LEFT JOIN category_ratings cr
    ON ci.i_category_id = cr.i_category_id
    AND ci.i_category_name = cr.i_category_name
LEFT JOIN category_prices cp
    ON ci.i_category_id = cp.i_category_id
    AND ci.i_category_name = cp.i_category_name
LEFT JOIN (
    SELECT i_category_id, i_category_name, s_store_id, store_quantity
    FROM top_store_per_category
    WHERE rn = 1
) ts
    ON ci.i_category_id = ts.i_category_id
    AND ci.i_category_name = ts.i_category_name
LEFT JOIN stores s
    ON ts.s_store_id = s.s_store_id
ORDER BY ci.i_category_id
