WITH agg AS (
  SELECT
    rc.cd_marital_status AS returning_marital_status,
    rc.cd_education_status AS returning_education_status,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_refunded_cash) AS total_refunded_cash,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_fee) AS avg_fee,
    AVG(rc.cd_dep_count) AS avg_dep_count
  FROM web_returns wr
  INNER JOIN customer_demographics rc
    ON wr.wr_returning_cdemo_sk = rc.cd_demo_sk
  INNER JOIN customer_demographics fc
    ON wr.wr_refunded_cdemo_sk = fc.cd_demo_sk
  WHERE rc.cd_dep_employed_count >= 2
    AND fc.cd_purchase_estimate >= 1500
  GROUP BY rc.cd_marital_status, rc.cd_education_status
)
SELECT
  returning_marital_status,
  returning_education_status,
  return_cnt,
  total_refunded_cash,
  total_net_loss,
  avg_fee,
  avg_dep_count,
  total_net_loss / NULLIF(total_refunded_cash, 0) AS net_loss_to_refunded_ratio,
  RANK() OVER (ORDER BY total_net_loss / NULLIF(total_refunded_cash, 0) DESC) AS loss_ratio_rank
FROM agg
ORDER BY net_loss_to_refunded_ratio DESC
LIMIT 10
