WITH sales_raw AS (
    SELECT i.i_category_id,
           i.i_category,
           ss.ss_quantity AS quantity,
           ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT i.i_category_id,
           i.i_category,
           ws.ws_quantity AS quantity,
           ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
category_sales AS (
    SELECT i_category_id AS category_id,
           i_category AS category,
           SUM(quantity) AS total_quantity,
           SUM(revenue) AS total_revenue
    FROM sales_raw
    GROUP BY i_category_id, i_category
),
category_reviews AS (
    SELECT i.i_category_id,
           i.i_category,
           COUNT(*) AS review_count,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT cs.category,
       cs.total_quantity,
       cs.total_revenue,
       COALESCE(cr.review_count, 0) AS total_reviews,
       cr.avg_sentiment AS avg_sentiment
FROM category_sales cs
LEFT JOIN category_reviews cr ON cs.category_id = cr.i_category_id
ORDER BY cs.total_quantity DESC
LIMIT 20
