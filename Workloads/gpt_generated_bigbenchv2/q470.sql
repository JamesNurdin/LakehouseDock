WITH
    store_agg AS (
        SELECT ss_item_id AS i_item_id,
               SUM(ss_quantity) AS store_quantity
        FROM store_sales
        GROUP BY ss_item_id
    ),
    web_agg AS (
        SELECT ws_item_id AS i_item_id,
               SUM(ws_quantity) AS web_quantity
        FROM web_sales
        GROUP BY ws_item_id
    ),
    review_agg AS (
        SELECT pr_item_id AS i_item_id,
               AVG(pr_rating) AS avg_rating,
               COUNT(*) AS review_count
        FROM product_reviews
        GROUP BY pr_item_id
    ),
    item_sales AS (
        SELECT i.i_item_id,
               i.i_name,
               i.i_category_id,
               i.i_category_name,
               i.i_price,
               i.i_comp_price,
               COALESCE(s.store_quantity, 0) AS store_quantity,
               COALESCE(w.web_quantity, 0) AS web_quantity,
               COALESCE(r.avg_rating, 0) AS avg_rating,
               COALESCE(r.review_count, 0) AS review_count
        FROM items i
        LEFT JOIN store_agg s ON i.i_item_id = s.i_item_id
        LEFT JOIN web_agg w ON i.i_item_id = w.i_item_id
        LEFT JOIN review_agg r ON i.i_item_id = r.i_item_id
    ),
    item_metrics AS (
        SELECT i.i_item_id,
               i.i_name,
               i.i_category_id,
               i.i_category_name,
               i.i_price,
               i.i_comp_price,
               i.store_quantity,
               i.web_quantity,
               (i.store_quantity + i.web_quantity) AS total_quantity,
               i.avg_rating,
               i.review_count,
               (i.i_price - i.i_comp_price) AS price_diff
        FROM item_sales i
    )
SELECT im.i_item_id,
       im.i_name,
       im.i_category_id,
       im.i_category_name,
       im.store_quantity,
       im.web_quantity,
       im.total_quantity,
       ROUND(im.avg_rating, 2) AS avg_rating,
       im.review_count,
       ROUND(im.price_diff, 2) AS price_diff,
       ROW_NUMBER() OVER (PARTITION BY im.i_category_id ORDER BY im.total_quantity DESC) AS category_item_rank,
       SUM(im.total_quantity) OVER (PARTITION BY im.i_category_id) AS category_total_quantity
FROM item_metrics im
WHERE im.total_quantity > 0
ORDER BY im.i_category_id,
         category_item_rank
LIMIT 50
