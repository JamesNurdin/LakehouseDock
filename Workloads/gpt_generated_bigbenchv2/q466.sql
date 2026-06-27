WITH combined_sales AS (
    SELECT ss_customer_id AS customer_id,
           ss_store_id   AS store_id,
           ss_item_id    AS item_id,
           ss_quantity   AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_customer_id AS customer_id,
           NULL           AS store_id,
           ws_item_id     AS item_id,
           ws_quantity    AS quantity
    FROM web_sales
),
item_ratings AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT COALESCE(s.s_store_name, 'Online')               AS store_name,
       i.i_category_name                               AS category_name,
       SUM(cs.quantity)                               AS total_quantity,
       SUM(i.i_price * cs.quantity)                   AS total_revenue,
       AVG(ir.avg_rating)                             AS avg_item_rating,
       COUNT(DISTINCT cs.customer_id)                 AS distinct_customers
FROM combined_sales cs
JOIN items i
  ON cs.item_id = i.i_item_id
LEFT JOIN stores s
  ON cs.store_id = s.s_store_id
LEFT JOIN item_ratings ir
  ON cs.item_id = ir.item_id
GROUP BY COALESCE(s.s_store_name, 'Online'), i.i_category_name
ORDER BY total_revenue DESC
LIMIT 50
