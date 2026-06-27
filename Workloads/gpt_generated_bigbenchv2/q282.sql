WITH unified_sales AS (
   SELECT ss.ss_quantity AS quantity,
          ss.ss_customer_id AS customer_id,
          ss.ss_item_id AS item_id,
          ss.ss_store_id AS store_id
   FROM store_sales ss
   UNION ALL
   SELECT ws.ws_quantity AS quantity,
          ws.ws_customer_id AS customer_id,
          ws.ws_item_id AS item_id,
          CAST(NULL AS bigint) AS store_id
   FROM web_sales ws
),
sales_with_details AS (
   SELECT us.quantity,
          us.customer_id,
          i.i_item_id,
          i.i_category_id,
          i.i_category_name,
          i.i_price,
          s.s_store_name
   FROM unified_sales us
   JOIN items i ON us.item_id = i.i_item_id
   LEFT JOIN stores s ON us.store_id = s.s_store_id
),
sales_agg AS (
   SELECT
      COALESCE(swd.s_store_name, 'Online') AS store_name,
      swd.i_category_id,
      swd.i_category_name,
      SUM(swd.quantity) AS total_quantity,
      SUM(swd.quantity * swd.i_price) AS total_revenue,
      COUNT(DISTINCT swd.customer_id) AS distinct_customers
   FROM sales_with_details swd
   GROUP BY COALESCE(swd.s_store_name, 'Online'), swd.i_category_id, swd.i_category_name
),
rating_agg AS (
   SELECT
      i.i_category_id,
      i.i_category_name,
      AVG(pr.pr_rating) AS avg_rating
   FROM product_reviews pr
   JOIN items i ON pr.pr_item_id = i.i_item_id
   GROUP BY i.i_category_id, i.i_category_name
)
SELECT
   sa.store_name,
   sa.i_category_name,
   sa.total_quantity,
   sa.total_revenue,
   ra.avg_rating,
   sa.distinct_customers
FROM sales_agg sa
LEFT JOIN rating_agg ra ON sa.i_category_id = ra.i_category_id
ORDER BY sa.total_revenue DESC
LIMIT 10
