WITH store_agg AS (
    SELECT i.i_item_id AS i_item_id,
           SUM(ss.ss_quantity) AS store_quantity,
           COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_agg AS (
    SELECT i.i_item_id AS i_item_id,
           SUM(ws.ws_quantity) AS web_quantity,
           COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
review_agg AS (
    SELECT pr.pr_item_id AS i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_cnt
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_category AS category,
       SUM(COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity_sold,
       AVG(i.i_price) AS avg_item_price,
       AVG(COALESCE(ra.avg_sentiment, 0)) AS avg_review_sentiment,
       COUNT(DISTINCT i.i_item_id) AS distinct_items_sold
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.i_item_id
GROUP BY i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
