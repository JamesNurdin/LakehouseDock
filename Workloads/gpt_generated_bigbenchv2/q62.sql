WITH distinct_categories AS (
    SELECT DISTINCT i_category_id, i_category
    FROM items
),
store_sales_cat AS (
    SELECT i.i_category_id,
           SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id
),
web_sales_cat AS (
    SELECT i.i_category_id,
           SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id
),
reviews_cat AS (
    SELECT i.i_category_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT dc.i_category_id,
       dc.i_category,
       COALESCE(ssc.total_store_quantity, 0) AS total_store_quantity,
       COALESCE(wsc.total_web_quantity, 0) AS total_web_quantity,
       COALESCE(rc.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(rc.review_count, 0) AS review_count
FROM distinct_categories dc
LEFT JOIN store_sales_cat ssc ON ssc.i_category_id = dc.i_category_id
LEFT JOIN web_sales_cat wsc ON wsc.i_category_id = dc.i_category_id
LEFT JOIN reviews_cat rc ON rc.i_category_id = dc.i_category_id
ORDER BY total_store_quantity DESC
LIMIT 20
