WITH sales_union AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
sales_by_category AS (
    SELECT i.i_category AS category,
           SUM(su.quantity) AS total_quantity,
           SUM(su.quantity * i.i_price) AS total_revenue
    FROM sales_union su
    JOIN items i ON su.item_id = i.i_item_id
    GROUP BY i.i_category
),
sentiment_by_category AS (
    SELECT i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT sbc.category,
       sbc.total_quantity,
       sbc.total_revenue,
       COALESCE(sbc2.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(sbc2.review_count, 0) AS review_count
FROM sales_by_category sbc
LEFT JOIN sentiment_by_category sbc2
  ON sbc.category = sbc2.category
ORDER BY sbc.total_revenue DESC
LIMIT 10
