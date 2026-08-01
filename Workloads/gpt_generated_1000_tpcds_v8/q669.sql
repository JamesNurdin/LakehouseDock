WITH sales_sample AS (
   SELECT cs.cs_order_number,
          cs.cs_item_sk,
          cs.cs_quantity,
          cs.cs_net_paid
   FROM catalog_sales cs
   TABLESAMPLE BERNOULLI (10)
   WHERE cs.cs_sold_date_sk IN (
         SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2001
   )
),
sales_agg AS (
   SELECT cs_order_number,
          SUM(cs_net_paid) AS total_net_paid,
          COUNT(DISTINCT cs_item_sk) AS distinct_items
   FROM sales_sample
   GROUP BY cs_order_number
   HAVING SUM(cs_net_paid) > 1000
),
returns AS (
   SELECT cr.cr_order_number,
          SUM(cr.cr_net_loss) AS total_loss
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY cr.cr_order_number
   HAVING SUM(cr.cr_net_loss) > 0
),
promo_sales AS (
   SELECT cs.cs_order_number
   FROM catalog_sales cs
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
   JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
   WHERE d_start.d_year = 2001 AND d_end.d_year = 2001
),
warehouse_exclude AS (
   SELECT cs.cs_order_number
   FROM catalog_sales cs
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE w.w_state = 'TX'
),
union_set AS (
   SELECT cs_order_number AS order_number FROM sales_agg
   UNION
   SELECT cr_order_number AS order_number FROM returns
),
intersect_set AS (
   SELECT order_number FROM union_set
   INTERSECT
   SELECT cs_order_number FROM promo_sales
),
final_ids AS (
   SELECT order_number FROM intersect_set
   EXCEPT
   SELECT cs_order_number FROM warehouse_exclude
)
SELECT f.order_number,
       sa.total_net_paid,
       sa.distinct_items,
       (SELECT AVG(total_net_paid) FROM sales_agg) AS avg_total_net_paid
FROM final_ids f
LEFT JOIN sales_agg sa ON sa.cs_order_number = f.order_number
ORDER BY f.order_number
LIMIT 100
