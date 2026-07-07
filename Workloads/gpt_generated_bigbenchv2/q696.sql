WITH store_sales_agg AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
combined_sales AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category,
           i.i_price,
           COALESCE(s.store_quantity, 0) AS store_quantity,
           COALESCE(w.web_quantity, 0) AS web_quantity,
           (COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0)) AS total_quantity
    FROM items i
    LEFT JOIN store_sales_agg s ON i.i_item_id = s.item_id
    LEFT JOIN web_sales_agg w ON i.i_item_id = w.item_id
),
review_agg AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT cs.i_item_id,
       cs.i_name,
       cs.i_category,
       cs.i_price,
       cs.total_quantity,
       cs.store_quantity,
       cs.web_quantity,
       ra.avg_sentiment,
       ra.review_count
FROM combined_sales cs
LEFT JOIN review_agg ra ON cs.i_item_id = ra.item_id
ORDER BY cs.total_quantity DESC
LIMIT 10
