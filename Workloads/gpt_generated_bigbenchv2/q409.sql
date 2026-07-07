WITH sales AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
sales_agg AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category,
           SUM(s.quantity) AS total_quantity
    FROM sales s
    JOIN items i
      ON s.item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_name, i.i_category
),
review_agg AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i
      ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT s.i_item_id,
       s.i_name,
       s.i_category,
       s.total_quantity,
       r.avg_sentiment,
       r.review_count
FROM sales_agg s
LEFT JOIN review_agg r
  ON s.i_item_id = r.i_item_id
ORDER BY s.total_quantity DESC,
         r.avg_sentiment DESC NULLS LAST
