WITH unified_sales AS (
    SELECT ss_item_id AS item_id,
           ss_customer_id AS customer_id,
           ss_quantity AS quantity,
           ss_ts AS ts
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_customer_id AS customer_id,
           ws_quantity AS quantity,
           ws_ts AS ts
    FROM web_sales
),
item_sales_agg AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category_id,
           i.i_category_name,
           i.i_price,
           SUM(us.quantity) AS total_quantity,
           SUM(us.quantity * i.i_price) AS total_revenue,
           COUNT(DISTINCT us.customer_id) AS distinct_customers
    FROM unified_sales us
    JOIN items i
      ON us.item_id = i.i_item_id
    GROUP BY i.i_item_id,
             i.i_name,
             i.i_category_id,
             i.i_category_name,
             i.i_price
),
item_reviews_agg AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category_id,
           i.i_category_name,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
      ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id,
             i.i_name,
             i.i_category_id,
             i.i_category_name
)
SELECT s.i_category_name,
       s.i_category_id,
       s.i_item_id,
       s.i_name,
       s.total_quantity,
       s.total_revenue,
       s.distinct_customers,
       r.avg_rating,
       r.review_count
FROM item_sales_agg s
LEFT JOIN item_reviews_agg r
  ON s.i_item_id = r.i_item_id
ORDER BY s.total_revenue DESC
LIMIT 100
