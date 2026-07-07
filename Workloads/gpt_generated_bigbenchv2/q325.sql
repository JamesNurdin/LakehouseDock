WITH sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
category_sales AS (
    SELECT i.i_category AS category,
           SUM(s.quantity) AS total_quantity
    FROM sales s
    JOIN items i ON s.item_id = i.i_item_id
    GROUP BY i.i_category
),
category_sentiment AS (
    SELECT i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT cs.category,
       cs.total_quantity,
       csent.avg_sentiment
FROM category_sales cs
LEFT JOIN category_sentiment csent
    ON cs.category = csent.category
ORDER BY cs.total_quantity DESC
