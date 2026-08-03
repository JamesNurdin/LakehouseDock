WITH avg_net AS (
   SELECT avg(cs_net_paid_inc_ship) AS avg_net
   FROM catalog_sales
)
SELECT
   product_name,
   size,
   total_net_paid,
   CASE
       WHEN total_net_paid > (SELECT avg_net FROM avg_net) THEN 'above_avg'
       ELSE 'below_avg'
   END AS relative_to_avg,
   category_id
FROM (
   SELECT
       i.i_product_name AS product_name,
       i.i_size AS size,
       SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
       i.i_category_id AS category_id
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   WHERE i.i_category_id IN (2, 4)
     AND td.t_sub_shift = 'afternoon'
   GROUP BY i.i_product_name, i.i_size, i.i_category_id
   UNION ALL
   SELECT
       i.i_product_name AS product_name,
       i.i_size AS size,
       SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
       i.i_category_id AS category_id
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   WHERE i.i_category_id = 8
     AND td.t_sub_shift = 'night'
   GROUP BY i.i_product_name, i.i_size, i.i_category_id
) t
ORDER BY total_net_paid DESC
LIMIT 100
