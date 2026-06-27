WITH sales_union AS (
    SELECT ss_customer_id AS customer_id,
           ss_item_id    AS item_id,
           ss_quantity   AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_customer_id AS customer_id,
           ws_item_id    AS item_id,
           ws_quantity   AS quantity
    FROM web_sales
),
item_sales AS (
    SELECT s.item_id,
           SUM(s.quantity) AS total_quantity,
           SUM(s.quantity * i.i_price) AS total_revenue,
           COUNT(DISTINCT s.customer_id) AS distinct_customers
    FROM sales_union s
    JOIN items i
      ON s.item_id = i.i_item_id
    GROUP BY s.item_id
),
item_rating AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_category_id,
       i.i_category_name,
       SUM(isales.total_quantity) AS category_quantity,
       SUM(isales.total_revenue) AS category_revenue,
       AVG(ir.avg_rating) AS category_avg_rating,
       SUM(isales.distinct_customers) AS category_distinct_customers
FROM item_sales isales
JOIN items i
  ON isales.item_id = i.i_item_id
LEFT JOIN item_rating ir
  ON isales.item_id = ir.item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY category_revenue DESC
