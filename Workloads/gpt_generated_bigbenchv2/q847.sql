WITH sales_by_store_category AS (
    SELECT s.s_store_id,
           s.s_store_name,
           i.i_category,
           SUM(i.i_price * ss.ss_quantity) AS total_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category
),
sentiment_by_category AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT sbc.s_store_name,
       sbc.i_category,
       sbc.total_revenue,
       sbc2.avg_sentiment
FROM sales_by_store_category sbc
JOIN sentiment_by_category sbc2
  ON sbc.i_category = sbc2.i_category
ORDER BY sbc.total_revenue DESC
LIMIT 10
