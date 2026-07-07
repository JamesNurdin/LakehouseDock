WITH sales_union AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(su.quantity) AS total_quantity
    FROM sales_union su
    JOIN items i ON su.item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT s.i_category_id,
       s.i_category,
       s.total_quantity,
       COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(r.review_count, 0) AS review_count
FROM sales_agg s
LEFT JOIN reviews_agg r
  ON s.i_category_id = r.i_category_id
ORDER BY s.total_quantity DESC
LIMIT 5
