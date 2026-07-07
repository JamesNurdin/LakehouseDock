WITH combined_sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity,
           'web' AS channel
    FROM web_sales
),
sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(CASE WHEN cs.channel = 'store' THEN cs.quantity ELSE 0 END) AS total_store_quantity,
           SUM(CASE WHEN cs.channel = 'store' THEN i.i_price * cs.quantity ELSE 0 END) AS total_store_revenue,
           SUM(CASE WHEN cs.channel = 'web' THEN cs.quantity ELSE 0 END) AS total_web_quantity,
           SUM(CASE WHEN cs.channel = 'web' THEN i.i_price * cs.quantity ELSE 0 END) AS total_web_revenue
    FROM combined_sales cs
    JOIN items i
      ON cs.item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i
      ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT sa.i_category_id,
       sa.i_category,
       sa.total_store_quantity,
       sa.total_store_revenue,
       sa.total_web_quantity,
       sa.total_web_revenue,
       ra.avg_sentiment
FROM sales_agg sa
LEFT JOIN review_agg ra
  ON sa.i_category_id = ra.i_category_id
ORDER BY (sa.total_store_revenue + sa.total_web_revenue) DESC
LIMIT 20
