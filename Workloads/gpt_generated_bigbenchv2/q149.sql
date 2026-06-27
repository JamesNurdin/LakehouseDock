WITH store_agg AS (
    SELECT ss_item_id AS i_item_id, SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id AS i_item_id, SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id AS i_item_id, COUNT(*) AS review_cnt, AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
store_count_agg AS (
    SELECT i.i_category_id, COUNT(DISTINCT ss.ss_store_id) AS distinct_store_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    COALESCE(SUM(sa.store_qty), 0) AS total_store_quantity,
    COALESCE(SUM(wa.web_qty), 0) AS total_web_quantity,
    COALESCE(SUM(sa.store_qty), 0) + COALESCE(SUM(wa.web_qty), 0) AS total_quantity,
    COALESCE(SUM(ra.review_cnt), 0) AS total_review_count,
    CASE WHEN SUM(ra.review_cnt) > 0 THEN SUM(ra.avg_rating * ra.review_cnt) / SUM(ra.review_cnt) ELSE NULL END AS avg_category_rating,
    AVG(i.i_price) AS avg_item_price,
    MIN(i.i_price) AS min_item_price,
    MAX(i.i_price) AS max_item_price,
    COALESCE(MAX(sca.distinct_store_count), 0) AS distinct_store_count
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.i_item_id
LEFT JOIN store_count_agg sca ON i.i_category_id = sca.i_category_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_quantity DESC
LIMIT 10
