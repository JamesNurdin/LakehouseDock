WITH store_sales_agg AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
reviews_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS rating_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
items_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        AVG(i.i_price) AS avg_price,
        COUNT(i.i_item_id) AS item_count
    FROM items i
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    ss.store_name,
    ss.category_name,
    ss.total_store_quantity,
    COALESCE(ws.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(rv.avg_rating, 0) AS avg_rating,
    COALESCE(rv.rating_count, 0) AS rating_count,
    COALESCE(it.avg_price, 0) AS avg_price,
    COALESCE(it.item_count, 0) AS item_count
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws ON ss.category_id = ws.category_id
LEFT JOIN reviews_agg rv ON ss.category_id = rv.category_id
LEFT JOIN items_agg it ON ss.category_id = it.category_id
ORDER BY ss.store_name, ss.category_name
