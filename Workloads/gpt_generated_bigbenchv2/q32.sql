/*
Goal: Identify the top 10 stores by total quantity sold and show the average product review sentiment for the items each store sells.
*/
WITH store_sales_agg AS (
    SELECT ss.ss_store_id,
           SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_id
),
store_sentiment AS (
    SELECT ss.ss_store_id,
           SUM(pr.pr_sentiment) AS sum_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM store_sales ss
    JOIN items i
      ON ss.ss_item_id = i.i_item_id
    JOIN product_reviews pr
      ON pr.pr_item_id = i.i_item_id
    GROUP BY ss.ss_store_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    COALESCE(sa.total_quantity, 0) AS total_quantity,
    CASE
        WHEN COALESCE(ssum.review_count, 0) > 0 THEN COALESCE(ssum.sum_sentiment, 0) / COALESCE(ssum.review_count, 0)
        ELSE NULL
    END AS avg_sentiment,
    COALESCE(ssum.review_count, 0) AS total_reviews
FROM stores s
LEFT JOIN store_sales_agg sa
  ON s.s_store_id = sa.ss_store_id
LEFT JOIN store_sentiment ssum
  ON s.s_store_id = ssum.ss_store_id
ORDER BY total_quantity DESC
LIMIT 10
