WITH sampled_returns AS (
   SELECT cr_returned_date_sk,
          cr_refunded_cdemo_sk,
          cr_returning_cdemo_sk,
          cr_warehouse_sk,
          cr_return_quantity,
          cr_return_amount,
          cr_net_loss,
          cr_order_number
   FROM catalog_returns
   TABLESAMPLE BERNOULLI (10)
),
order_set_a AS (
   SELECT cr_order_number
   FROM catalog_returns
   WHERE cr_warehouse_sk = 5
),
order_set_b AS (
   SELECT cr_order_number
   FROM catalog_returns
   WHERE cr_warehouse_sk = 7
),
filtered_orders AS (
   SELECT cr_order_number
   FROM order_set_a
   EXCEPT
   SELECT cr_order_number
   FROM order_set_b
),
agg_returns AS (
   SELECT
      d.d_year,
      sr.cr_warehouse_sk,
      cd_ret.cd_gender,
      SUM(sr.cr_net_loss) AS total_net_loss,
      COUNT(*) AS return_cnt,
      AVG(sr.cr_return_quantity) AS avg_return_qty
   FROM sampled_returns sr
   JOIN date_dim d
     ON sr.cr_returned_date_sk = d.d_date_sk
   JOIN customer_demographics cd_ref
     ON sr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
   JOIN customer_demographics cd_ret
     ON sr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
   WHERE d.d_year BETWEEN 2000 AND 2005
     AND d.d_current_month = 'Y'
     AND sr.cr_return_quantity > 10
     AND sr.cr_warehouse_sk IN (3, 5, 7)
     AND cd_ret.cd_dep_employed_count >= 2
     AND cd_ref.cd_credit_rating = 'Good'
     AND sr.cr_order_number IN (SELECT cr_order_number FROM filtered_orders)
   GROUP BY d.d_year, sr.cr_warehouse_sk, cd_ret.cd_gender
)
SELECT
   d_year,
   cr_warehouse_sk,
   total_net_loss,
   return_cnt,
   avg_return_qty,
   CASE WHEN cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS returning_gender,
   RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS loss_rank
FROM agg_returns
ORDER BY d_year DESC, total_net_loss DESC
LIMIT 100
