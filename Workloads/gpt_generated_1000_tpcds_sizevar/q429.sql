WITH sampled_returns AS (
   SELECT *
   FROM catalog_returns
   TABLESAMPLE BERNOULLI (10)
),
joined_full AS (
   SELECT
       sr.cr_returning_customer_sk,
       sr.cr_returning_cdemo_sk,
       sr.cr_warehouse_sk,
       sr.cr_return_amount,
       sr.cr_return_tax,
       sr.cr_return_quantity,
       sr.cr_return_amt_inc_tax,
       sr.cr_refunded_cash,
       cd.cd_gender,
       cd.cd_dep_count,
       cd.cd_purchase_estimate,
       w.w_warehouse_name,
       w.w_county
   FROM sampled_returns sr
   FULL OUTER JOIN warehouse w
       ON sr.cr_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN customer_demographics cd
       ON sr.cr_returning_cdemo_sk = cd.cd_demo_sk
   WHERE sr.cr_return_amount > 100
     AND sr.cr_return_tax < 50
     AND cd.cd_gender = 'F'
     AND cd.cd_dep_count <= 2
     AND w.w_county = 'Franklin Parish'
),
agg1 AS (
   SELECT
       cr_returning_customer_sk,
       SUM(cr_return_amount) AS total_return_amount,
       AVG(cr_return_quantity) AS avg_return_qty,
       COUNT(*) AS cnt_returns
   FROM joined_full
   GROUP BY cr_returning_customer_sk
),
agg2 AS (
   SELECT
       cr_returning_customer_sk,
       SUM(cr_return_amount) AS total_return_amount,
       AVG(cr_return_quantity) AS avg_return_qty,
       COUNT(*) AS cnt_returns
   FROM joined_full
   WHERE cr_return_amount > 500
   GROUP BY cr_returning_customer_sk
),
union_agg AS (
   SELECT * FROM agg1
   UNION
   SELECT * FROM agg2
),
intersect_keys AS (
   SELECT cr_returning_customer_sk FROM agg1
   INTERSECT
   SELECT cr_returning_customer_sk FROM agg2
)
SELECT
   u.cr_returning_customer_sk,
   u.total_return_amount,
   u.avg_return_qty,
   u.cnt_returns
FROM union_agg u
WHERE u.cr_returning_customer_sk IN (SELECT cr_returning_customer_sk FROM intersect_keys)
ORDER BY u.total_return_amount DESC
LIMIT 100
