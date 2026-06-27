WITH
    store_agg AS (
        SELECT ss_item_id,
               SUM(ss_quantity) AS store_quantity
        FROM store_sales
        GROUP BY ss_item_id
    ),
    web_agg AS (
        SELECT ws_item_id,
               SUM(ws_quantity) AS web_quantity
        FROM web_sales
        GROUP BY ws_item_id
    ),
    review_agg AS (
        SELECT pr_item_id,
               COUNT(*) AS review_count,
               AVG(pr_rating) AS avg_rating
        FROM product_reviews
        GROUP BY pr_item_id
    ),
    item_sales AS (
        SELECT
            i.i_item_id,
            i.i_name,
            i.i_category_name,
            i.i_price,
            COALESCE(r.review_count, 0) AS review_count,
            COALESCE(r.avg_rating, 0) AS avg_rating,
            COALESCE(s.store_quantity, 0) AS store_quantity,
            COALESCE(w.web_quantity, 0) AS web_quantity,
            (COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0)) AS total_quantity,
            (COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0)) * i.i_price AS total_revenue
        FROM items i
        LEFT JOIN store_agg s
            ON s.ss_item_id = i.i_item_id
        LEFT JOIN web_agg w
            ON w.ws_item_id = i.i_item_id
        LEFT JOIN review_agg r
            ON r.pr_item_id = i.i_item_id
        WHERE i.i_price > 0
    )
SELECT
    i_item_id,
    i_name,
    i_category_name,
    i_price,
    review_count,
    avg_rating,
    store_quantity,
    web_quantity,
    total_quantity,
    total_revenue,
    ROW_NUMBER() OVER (PARTITION BY i_category_name ORDER BY total_revenue DESC) AS category_rank
FROM item_sales
WHERE total_revenue > 0
ORDER BY total_revenue DESC
LIMIT 20
