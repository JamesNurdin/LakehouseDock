WITH filtered AS (
  SELECT
    cr.cr_refunded_customer_sk AS refunded_customer_sk,
    cr.cr_return_amount,
    cr.cr_net_loss,
    cr.cr_return_quantity,
    cr.cr_return_ship_cost,
    c.c_customer_id,
    c.c_first_name,
    c.c_birth_day,
    cd.cd_credit_rating,
    cd.cd_dep_employed_count,
    cd.cd_dep_college_count
  FROM catalog_returns cr
  JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE cr.cr_net_loss > 1000
    AND cr.cr_return_ship_cost < 1500
    AND cd.cd_credit_rating = 'High Risk'
    AND cd.cd_dep_employed_count >= 2
    AND c.c_birth_day IN (17, 21)
    AND cr.cr_return_quantity > 0
)
SELECT
  f.c_customer_id,
  f.cd_credit_rating,
  SUM(f.cr_return_amount) AS total_return_amount,
  AVG(f.cr_net_loss) AS avg_net_loss,
  COUNT(*) AS return_cnt,
  MIN(f.cr_return_ship_cost) AS min_ship_cost,
  MAX(f.cr_return_ship_cost) AS max_ship_cost,
  (SELECT AVG(cr2.cr_return_amount)
   FROM catalog_returns cr2
   WHERE cr2.cr_return_quantity > 1) AS overall_avg_return_amount
FROM filtered f
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr_ex
    WHERE cr_ex.cr_refunded_customer_sk = f.refunded_customer_sk
      AND cr_ex.cr_net_loss < 500
)
GROUP BY ROLLUP (f.c_customer_id, f.cd_credit_rating)
HAVING SUM(f.cr_return_amount) > 500
ORDER BY total_return_amount DESC
