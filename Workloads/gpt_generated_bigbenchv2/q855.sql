WITH sales_union AS (
    SELECT i.i_item_id AS item_id,
           i.i_price * ss.ss_quantity AS revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT i.i_item_id AS item_id,
           i.i_price * ws.ws_quantity AS revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
item_sales AS (
    SELECT item_id,
           SUM(revenue) AS total_revenue
    FROM sales_union
    GROUP BY item_id
),
item_reviews AS (
    SELECT i.i_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT i.i_category_id,
       i.i_category,
       SUM(COALESCE(isales.total_revenue, 0)) AS category_revenue,
       AVG(ir.avg_sentiment) AS category_avg_sentiment,
       SUM(ir.review_count) AS category_review_count
FROM items i
LEFT JOIN item_sales isales ON isales.item_id = i.i_item_id
LEFT JOIN item_reviews ir ON ir.item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY category_revenue DESC
LIMIT 10
