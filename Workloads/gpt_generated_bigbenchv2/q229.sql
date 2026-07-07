WITH store_sales_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
),
item_metrics AS (
    SELECT i.i_item_id,
           i.i_category_id,
           i.i_category,
           COALESCE(ss.store_qty, 0) + COALESCE(ws.web_qty, 0) AS total_quantity,
           rev.avg_sentiment
    FROM items i
    LEFT JOIN store_sales_agg ss ON ss.ss_item_id = i.i_item_id
    LEFT JOIN web_sales_agg ws ON ws.ws_item_id = i.i_item_id
    LEFT JOIN review_agg rev ON rev.pr_item_id = i.i_item_id
)
SELECT im.i_category_id,
       im.i_category,
       SUM(im.total_quantity) AS total_quantity,
       AVG(im.avg_sentiment) AS avg_sentiment
FROM item_metrics im
GROUP BY im.i_category_id, im.i_category
ORDER BY total_quantity DESC
LIMIT 5
