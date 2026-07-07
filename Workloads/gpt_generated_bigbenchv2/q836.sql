WITH store_item_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_item_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
review_item_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_cnt
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    SUM(COALESCE(si.store_qty, 0) + COALESCE(wi.web_qty, 0)) AS total_quantity_sold,
    AVG(i.i_price) AS avg_item_price,
    AVG(ri.avg_sentiment) AS avg_review_sentiment,
    SUM(ri.review_cnt) AS total_review_count
FROM items i
LEFT JOIN store_item_agg si ON i.i_item_id = si.ss_item_id
LEFT JOIN web_item_agg wi ON i.i_item_id = wi.ws_item_id
LEFT JOIN review_item_agg ri ON i.i_item_id = ri.pr_item_id
GROUP BY i.i_category_id, i.i_category
HAVING SUM(COALESCE(si.store_qty, 0) + COALESCE(wi.web_qty, 0)) > 0
ORDER BY total_quantity_sold DESC
LIMIT 20
