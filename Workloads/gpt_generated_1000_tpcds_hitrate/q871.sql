WITH
  agg_store AS (
    SELECT
      sr_hdemo_sk AS hd_demo_sk,
      SUM(sr_return_amt) AS total_sr_return_amt,
      COUNT(*) AS cnt_sr_returns,
      ARRAY_AGG(sr_return_amt) AS sr_return_amt_array
    FROM store_returns
    WHERE sr_fee > 30.0
      AND sr_return_quantity >= 1
    GROUP BY sr_hdemo_sk
  ),
  agg_web AS (
    SELECT
      wr_refunded_hdemo_sk AS hd_demo_sk,
      SUM(wr_return_amt) AS total_wr_return_amt,
      COUNT(*) AS cnt_wr_returns,
      ARRAY_AGG(wr_return_amt) AS wr_return_amt_array
    FROM web_returns
    WHERE wr_account_credit BETWEEN 20 AND 150
      AND wr_return_ship_cost > 50
    GROUP BY wr_refunded_hdemo_sk
  )
SELECT
  hd.hd_demo_sk,
  hd.hd_buy_potential,
  hd.hd_vehicle_count,
  CASE WHEN hd.hd_vehicle_count >= 2 THEN 'Multiple' ELSE 'Few' END AS vehicle_category,
  s.total_sr_return_amt,
  w.total_wr_return_amt,
  s.cnt_sr_returns,
  w.cnt_wr_returns,
  dim.region,
  ROW_NUMBER() OVER (PARTITION BY hd.hd_buy_potential ORDER BY s.total_sr_return_amt DESC) AS rn_by_buy_pot,
  (SELECT MAX(total_sr_return_amt) FROM agg_store) AS max_store_return,
  r.return_amt AS exploded_sr_return_amt
FROM household_demographics hd
JOIN agg_store s
  ON hd.hd_demo_sk = s.hd_demo_sk
LEFT JOIN agg_web w
  ON hd.hd_demo_sk = w.hd_demo_sk
JOIN web_returns wr
  ON hd.hd_demo_sk = wr.wr_returning_hdemo_sk
CROSS JOIN (SELECT 'North' AS region UNION ALL SELECT 'South' AS region) dim
CROSS JOIN UNNEST(s.sr_return_amt_array) AS r(return_amt)
WHERE hd.hd_buy_potential NOT IN ('Unknown')
  AND hd.hd_dep_count >= 3
  AND hd.hd_vehicle_count <> -1
  AND NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_refunded_hdemo_sk = hd.hd_demo_sk
      AND wr2.wr_return_quantity > 5
  )
LIMIT 100
