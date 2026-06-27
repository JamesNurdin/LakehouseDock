WITH sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity,
           ss_ts AS ts
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity,
           ws_ts AS ts
    FROM web_sales
),

sales_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(s.quantity) AS total_quantity,
           SUM(s.quantity * i.i_price) AS total_revenue
    FROM sales s
    JOIN items i
      ON s.item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),

review_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           COUNT(pr.pr_review_id) AS review_count,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
      ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT s.i_category_id,
       s.i_category_name,
       s.total_quantity,
       s.total_revenue,
       COALESCE(r.review_count, 0) AS review_count,
       r.avg_rating
FROM sales_agg s
LEFT JOIN review_agg r
  ON s.i_category_id = r.i_category_id
ORDER BY s.total_revenue DESC
LIMIT 10
