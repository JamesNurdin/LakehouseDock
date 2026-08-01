WITH sales_data AS (
   SELECT
       d.d_year,
       cc.cc_name,
       SUM(cs.cs_net_paid) AS total_net_paid,
       COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
       COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
       CASE WHEN SUM(cs.cs_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS sales_level
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY ROLLUP (d.d_year, cc.cc_name)
   HAVING SUM(cs.cs_net_paid) > 0
),
returns_data AS (
   SELECT
       d.d_year,
       cc.cc_name,
       SUM(cr.cr_net_loss) AS total_net_loss,
       COUNT(DISTINCT cr.cr_item_sk) AS distinct_return_items,
       COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
       CASE WHEN SUM(cr.cr_net_loss) > 50000 THEN 'HighLoss' ELSE 'LowLoss' END AS loss_level
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY ROLLUP (d.d_year, cc.cc_name)
   HAVING SUM(cr.cr_net_loss) > 0
),
union_data AS (
   SELECT d_year,
          cc_name,
          'sales'   AS metric_type,
          total_net_paid AS metric_value,
          distinct_items,
          distinct_orders,
          sales_level   AS level
   FROM sales_data
   UNION
   SELECT d_year,
          cc_name,
          'returns' AS metric_type,
          total_net_loss AS metric_value,
          distinct_return_items AS distinct_items,
          distinct_return_orders AS distinct_orders,
          loss_level   AS level
   FROM returns_data
),
order_exclusive AS (
   SELECT so.cs_order_number
   FROM catalog_sales so
   EXCEPT
   SELECT cr.cr_order_number
   FROM catalog_returns cr
),
final AS (
   SELECT
       ud.d_year,
       ud.cc_name,
       ud.metric_type,
       ud.metric_value,
       ud.distinct_items,
       ud.distinct_orders,
       ud.level,
       (SELECT AVG(total_net_paid) FROM sales_data) AS avg_yearly_sales,
       COUNT(*) OVER (PARTITION BY ud.cc_name ORDER BY ud.d_year
                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_rows,
       SUM(ud.metric_value) OVER (PARTITION BY ud.cc_name ORDER BY ud.d_year
                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_metric_total
   FROM union_data ud
   WHERE ud.d_year IS NOT NULL
     AND ud.cc_name IS NOT NULL
)
SELECT
    f.d_year,
    f.cc_name,
    f.metric_type,
    f.metric_value,
    f.distinct_items,
    f.distinct_orders,
    f.level,
    f.avg_yearly_sales,
    f.running_rows,
    f.running_metric_total,
    (SELECT COUNT(*) FROM order_exclusive) AS exclusive_order_count
FROM final f
ORDER BY f.d_year DESC, f.cc_name, f.metric_type
LIMIT 100
