WITH sales AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
category_revenue AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(i.i_price * s.quantity) AS total_revenue
    FROM sales s
    JOIN items i ON s.item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
category_sentiment AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT cr.i_category,
       cr.total_revenue,
       cs.avg_sentiment
FROM category_revenue cr
JOIN category_sentiment cs
  ON cr.i_category_id = cs.i_category_id
ORDER BY cr.total_revenue DESC
LIMIT 5
