WITH categories AS (
    SELECT DISTINCT i_category_id, i_category
    FROM items
),
store_sales_agg AS (
    SELECT i.i_category_id,
           SUM(ss.ss_quantity) AS store_qty,
           COUNT(DISTINCT ss.ss_store_id) AS store_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id
),
web_sales_agg AS (
    SELECT i.i_category_id,
           SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id
),
sentiment_agg AS (
    SELECT i.i_category_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT c.i_category_id,
       c.i_category,
       COALESCE(ss.store_qty, 0) AS total_store_quantity,
       COALESCE(ss.store_count, 0) AS distinct_store_count,
       COALESCE(ws.web_qty, 0) AS total_web_quantity,
       COALESCE(sr.avg_sentiment, NULL) AS avg_sentiment,
       COALESCE(sr.review_cnt, 0) AS review_count
FROM categories c
LEFT JOIN store_sales_agg ss ON c.i_category_id = ss.i_category_id
LEFT JOIN web_sales_agg ws ON c.i_category_id = ws.i_category_id
LEFT JOIN sentiment_agg sr ON c.i_category_id = sr.i_category_id
ORDER BY c.i_category_id
