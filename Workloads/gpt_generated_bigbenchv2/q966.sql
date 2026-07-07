WITH sales_by_store_category AS (
    SELECT s.s_store_name,
           i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY s.s_store_name, i.i_category_id, i.i_category
),
sentiment_by_category AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT sb.s_store_name AS store_name,
       sb.i_category AS category,
       sb.total_store_quantity,
       sc.avg_sentiment,
       sc.review_count
FROM sales_by_store_category sb
JOIN sentiment_by_category sc
  ON sb.i_category_id = sc.i_category_id
 AND sb.i_category = sc.i_category
ORDER BY sb.total_store_quantity DESC
