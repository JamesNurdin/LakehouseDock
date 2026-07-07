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
SELECT i.i_category AS category,
       i.i_category_id,
       i.i_item_id,
       i.i_name,
       COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
       (COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) * i.i_price AS total_revenue,
       COALESCE(ss.store_customer_cnt, 0) + COALESCE(ws.web_customer_cnt, 0) AS total_customers,
       r.avg_sentiment,
       r.review_cnt
FROM items i
LEFT JOIN store_sales_agg ss ON ss.item_id = i.i_item_id
LEFT JOIN web_sales_agg ws ON ws.item_id = i.i_item_id
LEFT JOIN review_agg r ON r.item_id = i.i_item_id
WHERE i.i_category IS NOT NULL
ORDER BY total_quantity DESC
LIMIT 20
