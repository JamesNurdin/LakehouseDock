WITH demo_all AS (
  SELECT hd_demo_sk
  FROM household_demographics
),

demo_high_vehicle AS (
  SELECT hd_demo_sk
  FROM household_demographics
  WHERE hd_vehicle_count >= 2
),

demo_excluded AS (
  SELECT hd_demo_sk
  FROM demo_all
  EXCEPT
  SELECT hd_demo_sk
  FROM demo_high_vehicle
),

agg_by_demo AS (
  SELECT
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    AVG(sr.sr_return_tax) AS avg_return_tax
  FROM
    (SELECT * FROM store_returns TABLESAMPLE BERNOULLI (10)) sr
  JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN demo_excluded de
    ON hd.hd_demo_sk = de.hd_demo_sk
  WHERE
    hd.hd_vehicle_count >= 1
    AND hd.hd_dep_count BETWEEN 4 AND 8
    AND sr.sr_return_quantity > 1
    AND sr.sr_return_tax > 5
    AND sr.sr_return_amt_inc_tax < 500
    AND hd.hd_buy_potential IN ('HIGH','MEDIUM')
  GROUP BY
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    hd.hd_dep_count
),

final_agg AS (
  SELECT
    sub.hd_vehicle_count,
    AVG(sub.risk_score) AS avg_risk_score,
    SUM(sub.total_net_loss) AS sum_net_loss
  FROM (
    SELECT
      a.hd_vehicle_count,
      a.total_net_loss,
      a.return_cnt,
      a.avg_return_tax,
      l.risk_score
    FROM agg_by_demo a
    CROSS JOIN LATERAL (
      SELECT a.total_net_loss / NULLIF(a.return_cnt, 0) AS risk_score
    ) l
  ) sub
  GROUP BY sub.hd_vehicle_count
  HAVING AVG(sub.risk_score) > 0
)
SELECT
  hd_vehicle_count,
  avg_risk_score,
  sum_net_loss
FROM final_agg
ORDER BY avg_risk_score DESC
LIMIT 100
