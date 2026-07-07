WITH sales AS (
    SELECT i.i_category_id,
           i.i_category,
           ss.ss_quantity AS quantity,
           i.i_price AS price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT i.i_category_id,
           i.i_category,
           ws.ws_quantity AS quantity,
           i.i_price AS price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
category_sales AS (
    SELECT i_category_id,
           i_category,
           SUM(quantity) AS total_quantity,
           SUM(quantity * price) AS total_revenue
    FROM sales
    GROUP BY i_category_id, i_category
),
category_sentiment AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT cs.i_category_id,
       cs.i_category,
       cs.total_quantity,
       cs.total_revenue,
       COALESCE(csnt.avg_sentiment, 0) AS avg_sentiment
FROM category_sales cs
LEFT JOIN category_sentiment csnt ON cs.i_category_id = csnt.i_category_id
ORDER BY cs.total_revenue DESC
LIMIT 10
