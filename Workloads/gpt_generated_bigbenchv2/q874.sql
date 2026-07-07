WITH
store_agg AS (
    SELECT ss_item_id AS i_item_id,
           SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id AS i_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_cnt
    FROM product_reviews
    GROUP BY pr_item_id
),
category_store_counts AS (
    SELECT i.i_category,
           COUNT(DISTINCT s.s_store_id) AS distinct_store_cnt
    FROM items i
    JOIN store_sales ss ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON s.s_store_id = ss.ss_store_id
    GROUP BY i.i_category
)
SELECT
    i.i_category AS category,
    SUM(COALESCE(sa.store_qty, 0) * i.i_price) AS total_store_revenue,
    SUM(COALESCE(wa.web_qty, 0) * i.i_price) AS total_web_revenue,
    SUM(COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0)) AS total_quantity_sold,
    AVG(ra.avg_sentiment) AS avg_review_sentiment,
    COUNT(DISTINCT i.i_item_id) AS distinct_items_sold,
    COALESCE(csc.distinct_store_cnt, 0) AS distinct_stores_selling_category
FROM items i
LEFT JOIN store_agg sa ON sa.i_item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.i_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.i_item_id = i.i_item_id
LEFT JOIN category_store_counts csc ON csc.i_category = i.i_category
GROUP BY i.i_category, csc.distinct_store_cnt
ORDER BY total_store_revenue + total_web_revenue DESC
LIMIT 10
