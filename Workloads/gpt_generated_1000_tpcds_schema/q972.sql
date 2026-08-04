WITH
  filtered_returns AS (
    SELECT
      wr.wr_refunded_hdemo_sk AS demo_sk,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wr.wr_return_tax,
      wr.wr_return_ship_cost,
      wr.wr_account_credit,
      wr.wr_net_loss
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 1
      AND wr.wr_return_ship_cost > 20
      AND wr.wr_account_credit >= 10
      AND wr.wr_net_loss <> 0
      AND wr.wr_return_amt BETWEEN 50 AND 1000
  ),
  demo_subset AS (
    SELECT hd_demo_sk
    FROM household_demographics
    WHERE hd_dep_count >= 2
      AND hd_vehicle_count >= 0
      AND hd_buy_potential IN ('1001-5000', '>10000')
  ),
  common_demo AS (
    SELECT demo_sk
    FROM filtered_returns
    INTERSECT
    SELECT hd_demo_sk
    FROM demo_subset
  ),
  agg_per_demo AS (
    SELECT
      fr.demo_sk,
      SUM(fr.wr_return_amt) AS sum_return_amt,
      AVG(fr.wr_return_tax) AS avg_return_tax,
      COUNT(*) AS cnt_returns
    FROM filtered_returns fr
    JOIN common_demo cd ON fr.demo_sk = cd.demo_sk
    GROUP BY fr.demo_sk
  ),
  full_joined AS (
    SELECT
      hd.hd_demo_sk,
      hd.hd_buy_potential,
      hd.hd_dep_count,
      hd.hd_vehicle_count,
      agg.sum_return_amt,
      agg.avg_return_tax,
      agg.cnt_returns
    FROM household_demographics hd
    FULL OUTER JOIN agg_per_demo agg
      ON hd.hd_demo_sk = agg.demo_sk
    WHERE (hd.hd_dep_count IS NOT NULL AND hd.hd_vehicle_count IS NOT NULL)
       OR agg.sum_return_amt IS NOT NULL
  ),
  final AS (
    SELECT
      fj.hd_demo_sk,
      fj.hd_buy_potential,
      fj.sum_return_amt,
      fj.avg_return_tax,
      fj.cnt_returns,
      lt.total_refunded_amt
    FROM full_joined fj
    LEFT JOIN LATERAL (
      SELECT SUM(wr.wr_return_amt) AS total_refunded_amt
      FROM web_returns wr
      WHERE wr.wr_refunded_hdemo_sk = fj.hd_demo_sk
    ) lt ON TRUE
    WHERE fj.sum_return_amt > 100
  )
SELECT
  f.hd_demo_sk,
  f.hd_buy_potential,
  f.sum_return_amt,
  f.avg_return_tax,
  f.cnt_returns,
  f.total_refunded_amt
FROM final f
UNION DISTINCT
SELECT
  hd.hd_demo_sk,
  hd.hd_buy_potential,
  NULL AS sum_return_amt,
  NULL AS avg_return_tax,
  0 AS cnt_returns,
  0 AS total_refunded_amt
FROM household_demographics hd
WHERE hd.hd_buy_potential = 'Unknown'
LIMIT 100
