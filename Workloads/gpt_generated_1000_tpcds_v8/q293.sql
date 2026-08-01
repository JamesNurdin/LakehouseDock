WITH
  filtered_1913 AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_hdemo_sk,
      sr.sr_return_amt,
      sr.sr_fee,
      sr.sr_ticket_number,
      d.d_fy_year,
      hd.hd_buy_potential,
      hd.hd_dep_count,
      hd.hd_vehicle_count
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_fy_year = 1913
      AND hd.hd_buy_potential = '5001-10000'
  ),
  filtered_1911 AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_hdemo_sk,
      sr.sr_return_amt,
      sr.sr_fee,
      sr.sr_ticket_number,
      d.d_fy_year,
      hd.hd_buy_potential,
      hd.hd_dep_count,
      hd.hd_vehicle_count
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_fy_year = 1911
      AND hd.hd_buy_potential = '0-500'
  ),
  combined AS (
    SELECT
      sr_returned_date_sk,
      sr_hdemo_sk,
      sr_return_amt,
      sr_fee,
      sr_ticket_number,
      d_fy_year,
      hd_buy_potential,
      hd_dep_count,
      hd_vehicle_count
    FROM filtered_1913
    UNION ALL
    SELECT
      sr_returned_date_sk,
      sr_hdemo_sk,
      sr_return_amt,
      sr_fee,
      sr_ticket_number,
      d_fy_year,
      hd_buy_potential,
      hd_dep_count,
      hd_vehicle_count
    FROM filtered_1911
  )
SELECT
  c.sr_returned_date_sk,
  d.d_date,
  c.sr_hdemo_sk,
  c.hd_buy_potential,
  c.hd_dep_count,
  c.hd_vehicle_count,
  c.sr_return_amt,
  c.sr_fee,
  (c.sr_return_amt + c.sr_fee) AS total_return_amt,
  ROW_NUMBER() OVER (ORDER BY (c.sr_return_amt + c.sr_fee) DESC) AS global_row_num,
  LAG(c.sr_return_amt) OVER (PARTITION BY c.sr_hdemo_sk ORDER BY c.sr_ticket_number) AS prev_return_amt,
  lat.avg_return_amt_by_hdemo,
  (SELECT MAX(sr_fee) FROM store_returns) AS max_fee_overall,
  SUM(c.sr_return_amt) OVER (PARTITION BY c.sr_returned_date_sk ORDER BY c.sr_ticket_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sum_by_date
FROM combined c
JOIN date_dim d ON c.sr_returned_date_sk = d.d_date_sk
CROSS JOIN LATERAL (
  SELECT AVG(sr_return_amt) AS avg_return_amt_by_hdemo
  FROM store_returns sr4
  WHERE sr4.sr_hdemo_sk = c.sr_hdemo_sk
) AS lat
WHERE c.hd_vehicle_count >= 0
ORDER BY global_row_num
LIMIT 100
