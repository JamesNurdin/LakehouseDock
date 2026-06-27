WITH sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity,
           ss_customer_id AS customer_id,
           'store' AS channel,
           ss_store_id AS store_id
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity,
           ws_customer_id AS customer_id,
           'web' AS channel,
           NULL AS store_id
    FROM web_sales
),
sales_by_category AS (
    SELECT i.i_category_id,
           i.i_category_name,
           s.channel,
           SUM(s.quantity) AS total_quantity,
           COUNT(DISTINCT s.customer_id) AS unique_customers
    FROM sales s
    JOIN items i ON s.item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name, s.channel
),
rating_by_category AS (
    SELECT i.i_category_id,
           i.i_category_name,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT sbc.i_category_id,
       sbc.i_category_name,
       sbc.channel,
       sbc.total_quantity,
       sbc.unique_customers,
       rbc.avg_rating,
       rbc.review_count
FROM sales_by_category sbc
LEFT JOIN rating_by_category rbc
  ON sbc.i_category_id = rbc.i_category_id
ORDER BY sbc.i_category_id, sbc.channel
