WITH store_sales_agg AS (
    SELECT i.i_category AS i_category,
           SUM(ss.ss_quantity) AS total_store_quantity,
           COUNT(DISTINCT ss.ss_store_id) AS store_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT i.i_category AS i_category,
           SUM(ws.ws_quantity) AS total_web_quantity,
           COUNT(DISTINCT ws.ws_transaction_id) AS web_transaction_count
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
product_reviews_agg AS (
    SELECT i.i_category AS i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT s.i_category,
       s.total_store_quantity,
       s.store_count,
       w.total_web_quantity,
       w.web_transaction_count,
       p.avg_sentiment,
       p.review_count
FROM store_sales_agg s
LEFT JOIN web_sales_agg w
    ON s.i_category = w.i_category
LEFT JOIN product_reviews_agg p
    ON s.i_category = p.i_category
ORDER BY s.total_store_quantity DESC
