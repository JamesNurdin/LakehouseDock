WITH
  store_sales_agg AS (
    SELECT i.i_item_id,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
  ),
  web_sales_agg AS (
    SELECT i.i_item_id,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
  ),
  review_agg AS (
    SELECT i.i_item_id,
           SUM(pr.pr_sentiment) AS sentiment_sum,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    WHERE pr.pr_sentiment IS NOT NULL
    GROUP BY i.i_item_id
  )
SELECT i.i_category,
       i.i_category_id,
       SUM(COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity,
       SUM(COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0)) AS total_revenue,
       CASE
         WHEN SUM(COALESCE(r.review_count, 0)) = 0 THEN NULL
         ELSE CAST(SUM(COALESCE(r.sentiment_sum, 0)) AS double) / SUM(COALESCE(r.review_count, 0))
       END AS avg_sentiment
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN review_agg r ON i.i_item_id = r.i_item_id
GROUP BY i.i_category, i.i_category_id
HAVING SUM(COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) > 0
ORDER BY total_revenue DESC
LIMIT 10
