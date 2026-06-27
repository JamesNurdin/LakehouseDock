WITH sales_union AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity,
           ss_customer_id AS customer_id
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity,
           ws_customer_id AS customer_id
    FROM web_sales
),
sales_by_category AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(su.quantity) AS total_quantity,
           SUM(su.quantity * i.i_price) AS total_revenue,
           AVG(i.i_price) AS avg_price,
           COUNT(DISTINCT su.customer_id) AS distinct_customers
    FROM sales_union su
    JOIN items i
      ON su.item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
rating_by_category AS (
    SELECT i.i_category_id,
           i.i_category_name,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
      ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT sbc.i_category_id,
       sbc.i_category_name,
       sbc.total_quantity,
       sbc.total_revenue,
       sbc.avg_price,
       sbc.distinct_customers,
       rbc.avg_rating,
       rbc.review_count
FROM sales_by_category sbc
LEFT JOIN rating_by_category rbc
  ON sbc.i_category_id = rbc.i_category_id
 AND sbc.i_category_name = rbc.i_category_name
ORDER BY sbc.total_quantity DESC
LIMIT 10
