WITH sales AS (
    SELECT i.i_item_id,
           i.i_category,
           i.i_price,
           ss.ss_quantity AS quantity,
           ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN items i
      ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT i.i_item_id,
           i.i_category,
           i.i_price,
           ws.ws_quantity AS quantity,
           ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN items i
      ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT i_category,
           SUM(quantity) AS total_quantity,
           SUM(revenue) AS total_revenue
    FROM sales
    GROUP BY i_category
),
reviews_agg AS (
    SELECT i.i_category,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i
      ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT s.i_category,
       s.total_quantity,
       s.total_revenue,
       r.avg_sentiment,
       r.review_count
FROM sales_agg s
LEFT JOIN reviews_agg r
  ON s.i_category = r.i_category
ORDER BY s.total_revenue DESC
LIMIT 10
