WITH store_sales_agg AS (
    SELECT i.i_item_id,
           SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_sales_agg AS (
    SELECT i.i_item_id,
           SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
review_agg AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT i.i_category_id,
       i.i_category,
       SUM(COALESCE(sa.store_qty, 0)) AS total_store_quantity,
       SUM(COALESCE(wa.web_qty, 0)) AS total_web_quantity,
       AVG(ra.avg_sentiment) AS avg_sentiment,
       AVG(i.i_price) AS avg_price
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_store_quantity DESC
LIMIT 20
