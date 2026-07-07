WITH review_stats AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
),
store_sales_agg AS (
    SELECT i.i_category,
           'store' AS sales_channel,
           SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT i.i_category,
           'web' AS sales_channel,
           SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
combined_sales AS (
    SELECT i_category,
           sales_channel,
           total_quantity
    FROM store_sales_agg
    UNION ALL
    SELECT i_category,
           sales_channel,
           total_quantity
    FROM web_sales_agg
)
SELECT cs.i_category,
       cs.sales_channel,
       cs.total_quantity,
       rs.avg_sentiment
FROM combined_sales cs
LEFT JOIN review_stats rs
  ON cs.i_category = rs.i_category
ORDER BY cs.i_category, cs.sales_channel
