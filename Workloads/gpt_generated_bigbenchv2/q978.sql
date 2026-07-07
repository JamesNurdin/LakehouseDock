WITH categories AS (
    SELECT DISTINCT i.i_category_id, i.i_category
    FROM items i
),
store_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT c.i_category_id AS category_id,
       c.i_category AS category,
       COALESCE(ss.store_quantity, 0) AS store_quantity,
       COALESCE(ss.store_revenue, 0) AS store_revenue,
       COALESCE(ws.web_quantity, 0) AS web_quantity,
       COALESCE(ws.web_revenue, 0) AS web_revenue,
       COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(r.review_count, 0) AS review_count
FROM categories c
LEFT JOIN store_sales_agg ss ON c.i_category_id = ss.i_category_id
LEFT JOIN web_sales_agg ws ON c.i_category_id = ws.i_category_id
LEFT JOIN reviews_agg r ON c.i_category_id = r.i_category_id
ORDER BY c.i_category_id
