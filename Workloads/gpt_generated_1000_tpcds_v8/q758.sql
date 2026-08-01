WITH sampled_sales AS (
   SELECT *
   FROM catalog_sales TABLESAMPLE BERNOULLI (10)
),
sales_agg AS (
   SELECT
      cs.cs_sold_date_sk AS date_sk,
      SUM(cs.cs_net_paid) AS total_net_paid,
      SUM(cs.cs_quantity) AS total_qty
   FROM sampled_sales cs
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   WHERE td.t_shift = 'first'
   GROUP BY GROUPING SETS ((cs.cs_sold_date_sk), ())
),
returns_agg AS (
   SELECT
      cr.cr_returned_date_sk AS date_sk,
      SUM(cr.cr_return_amount) AS total_ret_amount,
      COUNT(*) AS ret_cnt
   FROM catalog_returns cr
   JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
   WHERE td.t_shift = 'first'
   GROUP BY cr.cr_returned_date_sk
),
union_agg AS (
   SELECT date_sk,
          total_net_paid,
          total_qty,
          NULL AS total_ret_amount,
          NULL AS ret_cnt
   FROM sales_agg
   UNION
   SELECT date_sk,
          NULL,
          NULL,
          total_ret_amount,
          ret_cnt
   FROM returns_agg
),
intersect_keys AS (
   SELECT cs.cs_order_number AS order_no
   FROM catalog_sales cs
   WHERE cs.cs_quantity > 0
   INTERSECT
   SELECT cr.cr_order_number
   FROM catalog_returns cr
   WHERE cr.cr_return_quantity > 0
),
final AS (
   SELECT u.date_sk,
          SUM(COALESCE(u.total_net_paid, 0)) AS agg_net_paid,
          SUM(COALESCE(u.total_qty, 0)) AS agg_qty,
          SUM(COALESCE(u.total_ret_amount, 0)) AS agg_ret_amount,
          SUM(COALESCE(u.ret_cnt, 0)) AS agg_ret_cnt
   FROM union_agg u
   WHERE u.date_sk NOT IN (SELECT order_no FROM intersect_keys)
   GROUP BY ROLLUP(u.date_sk)
   HAVING SUM(COALESCE(u.total_net_paid, 0)) > 1000
)
SELECT date_sk,
       agg_net_paid,
       agg_qty,
       agg_ret_amount,
       agg_ret_cnt
FROM final
ORDER BY agg_net_paid DESC
LIMIT 100
