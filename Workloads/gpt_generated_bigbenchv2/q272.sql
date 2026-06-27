WITH
    store_agg AS (
        SELECT i.i_item_id,
               SUM(ss.ss_quantity) AS store_quantity
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    web_agg AS (
        SELECT i.i_item_id,
               SUM(ws.ws_quantity) AS web_quantity
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    review_agg AS (
        SELECT i.i_item_id,
               COUNT(pr.pr_review_id) AS review_count,
               AVG(pr.pr_rating)      AS avg_rating
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    item_agg AS (
        SELECT i.i_item_id,
               i.i_category_id,
               i.i_category_name,
               i.i_price,
               i.i_comp_price,
               i.i_class_id,
               COALESCE(sa.store_quantity, 0) AS store_quantity,
               COALESCE(wa.web_quantity,   0) AS web_quantity,
               COALESCE(ra.review_count,  0) AS review_count,
               ra.avg_rating
        FROM items i
        LEFT JOIN store_agg sa   ON i.i_item_id = sa.i_item_id
        LEFT JOIN web_agg   wa   ON i.i_item_id = wa.i_item_id
        LEFT JOIN review_agg ra  ON i.i_item_id = ra.i_item_id
    )
SELECT
    i_category_id,
    i_category_name,
    COUNT(DISTINCT i_item_id)                     AS distinct_items,
    SUM(store_quantity)                           AS total_store_quantity,
    SUM(web_quantity)                             AS total_web_quantity,
    SUM(store_quantity + web_quantity)            AS total_quantity_sold,
    SUM((store_quantity + web_quantity) * i_price) AS total_revenue,
    AVG(i_price)                                  AS avg_item_price,
    SUM(review_count)                             AS total_review_count,
    AVG(avg_rating)                               AS avg_category_rating
FROM item_agg
GROUP BY i_category_id, i_category_name
ORDER BY total_revenue DESC
LIMIT 10
