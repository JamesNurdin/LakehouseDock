WITH store_sales_agg AS (
    SELECT ss.ss_item_id AS item_id,
           SUM(ss.ss_quantity) AS store_quantity,
           COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT ws.ws_item_id AS item_id,
           SUM(ws.ws_quantity) AS web_quantity,
           COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
review_agg AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_cnt
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0) AS total_quantity,
       COALESCE(ssa.store_customer_cnt, 0) + COALESCE(wsa.web_customer_cnt, 0) AS total_customer_cnt,
       ra.avg_sentiment,
       ra.review_cnt
FROM items i
LEFT JOIN store_sales_agg ssa ON ssa.item_id = i.i_item_id
LEFT JOIN web_sales_agg wsa ON wsa.item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.item_id = i.i_item_id
ORDER BY total_quantity DESC
LIMIT 10
