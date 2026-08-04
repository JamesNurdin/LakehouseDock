WITH catalog_orders AS (
   SELECT cs.cs_order_number AS order_id,
          i.i_category,
          d.d_year
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND i.i_class = 'furniture'
),
store_orders AS (
   SELECT ss.ss_ticket_number AS order_id,
          i.i_category,
          d.d_year
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND i.i_class = 'furniture'
)
SELECT order_id,
       source
FROM (
   SELECT order_id, 'catalog' AS source FROM catalog_orders
   UNION
   SELECT order_id, 'store'   AS source FROM store_orders
) AS base
EXCEPT (
   SELECT order_id, source
   FROM (
       SELECT cs.cs_order_number AS order_id, 'catalog' AS source
       FROM catalog_sales cs
       WHERE cs.cs_order_number IN (SELECT sr_ticket_number FROM store_returns)
       UNION
       SELECT ss.ss_ticket_number AS order_id, 'store' AS source
       FROM store_sales ss
       WHERE ss.ss_ticket_number IN (SELECT sr_ticket_number FROM store_returns)
   ) AS returned
)
INTERSECT (
   SELECT order_id, source
   FROM (
       SELECT cs.cs_order_number AS order_id, 'catalog' AS source
       FROM catalog_sales cs
       WHERE cs.cs_quantity >= 10
       UNION
       SELECT ss.ss_ticket_number AS order_id, 'store' AS source
       FROM store_sales ss
       WHERE ss.ss_quantity >= 10
   ) AS high_qty
)
ORDER BY order_id ASC, source
LIMIT 100
