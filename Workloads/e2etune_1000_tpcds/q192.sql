WITH filtered_returns AS (
  SELECT
    cr.cr_return_amount,
    cr.cr_net_loss,
    cr.cr_return_quantity,
    cr.cr_refunded_cash,
    cr.cr_warehouse_sk,
    t.t_hour AS hour_of_day,
    cd.cd_gender AS gender,
    cd.cd_education_status AS education_status
  FROM catalog_returns cr
  JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN customer_demographics cd
    ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
  WHERE cr.cr_return_amount > 0
    AND cr.cr_return_quantity > 0
    AND t.t_hour BETWEEN 8 AND 20
    AND cr.cr_warehouse_sk IN (5, 7, 8, 10, 17)
),
agg AS (
  SELECT
    hour_of_day,
    gender,
    COUNT(*) AS return_count,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(cr_return_quantity) AS avg_return_quantity,
    100.0 * SUM(CASE WHEN cr_refunded_cash > 1000 THEN 1 ELSE 0 END) / COUNT(*) AS pct_refunded_cash_gt_1000
  FROM filtered_returns
  GROUP BY hour_of_day, gender
  HAVING COUNT(*) >= 5
)
SELECT
  hour_of_day,
  gender,
  return_count,
  total_return_amount,
  total_net_loss,
  avg_return_quantity,
  pct_refunded_cash_gt_1000,
  RANK() OVER (PARTITION BY hour_of_day ORDER BY total_return_amount DESC) AS return_amount_rank_by_hour
FROM agg
ORDER BY hour_of_day, total_return_amount DESC
