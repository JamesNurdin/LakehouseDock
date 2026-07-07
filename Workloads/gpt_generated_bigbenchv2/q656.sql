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
reviews_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       COALESCE(sa.store_qty, 0) AS store_quantity,
       COALESCE(wa.web_qty, 0) AS web_quantity,
       ra.avg_sentiment,
       ra.review_count,
       (COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0)) AS total_quantity
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.ss_item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN reviews_agg ra ON i.i_item_id = ra.pr_item_id
WHERE (COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0)) > 0
ORDER BY total_quantity DESC
LIMIT 10
