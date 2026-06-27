WITH unified_sales AS (
   SELECT ss_customer_id AS customer_id,
          ss_item_id   AS item_id,
          ss_quantity  AS quantity
   FROM store_sales
   UNION ALL
   SELECT ws_customer_id,
          ws_item_id,
          ws_quantity
   FROM web_sales
),
category_sales AS (
   SELECT c.c_customer_id,
          c.c_name,
          i.i_category_id,
          i.i_category_name,
          SUM(u.quantity)                     AS total_quantity,
          SUM(i.i_price * u.quantity)          AS total_revenue
   FROM unified_sales u
   JOIN customers c ON u.customer_id = c.c_customer_id
   JOIN items i      ON u.item_id     = i.i_item_id
   GROUP BY c.c_customer_id, c.c_name, i.i_category_id, i.i_category_name
)
SELECT cs.c_customer_id,
       cs.c_name,
       cs.i_category_id,
       cs.i_category_name,
       cs.total_quantity,
       cs.total_revenue,
       ROW_NUMBER() OVER (PARTITION BY cs.i_category_id ORDER BY cs.total_revenue DESC) AS revenue_rank_in_category
FROM category_sales cs
ORDER BY cs.total_revenue DESC
LIMIT 100
