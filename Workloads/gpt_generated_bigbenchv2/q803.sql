WITH store_sales_agg AS (
    SELECT ss_item_id,
           sum(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id,
           sum(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
product_reviews_agg AS (
    SELECT pr_item_id,
           sum(pr_sentiment) AS total_sentiment,
           count(*) AS review_cnt
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category_id,
       i.i_category,
       COALESCE(SUM(ss.store_qty), 0) AS total_store_quantity,
       COALESCE(SUM(ws.web_qty), 0) AS total_web_quantity,
       COALESCE(SUM(ss.store_qty), 0) + COALESCE(SUM(ws.web_qty), 0) AS total_quantity,
       CASE WHEN SUM(pr.review_cnt) > 0 THEN SUM(pr.total_sentiment) / SUM(pr.review_cnt) ELSE NULL END AS avg_sentiment,
       SUM(pr.review_cnt) AS total_reviews
FROM items i
LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.ss_item_id
LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.ws_item_id
LEFT JOIN product_reviews_agg pr ON i.i_item_id = pr.pr_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity DESC
LIMIT 10
