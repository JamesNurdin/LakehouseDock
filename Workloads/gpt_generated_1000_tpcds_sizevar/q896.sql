WITH
  refunded AS (
    SELECT
      wr.wr_refunded_hdemo_sk AS hd_demo_sk,
      wr.wr_return_amt,
      wr.wr_return_quantity,
      hd.hd_income_band_sk,
      hd.hd_buy_potential,
      ROW_NUMBER() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY wr.wr_return_amt DESC) AS rnk
    FROM web_returns wr
    JOIN household_demographics hd
      ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(hd.hd_buy_potential, '(?i)^(high|medium)')
      AND hd.hd_buy_potential LIKE '%potential%'
  ),

  returning AS (
    SELECT DISTINCT wr.wr_returning_hdemo_sk AS hd_demo_sk
    FROM web_returns wr
  ),

  demo_exclusive AS (
    SELECT hd_demo_sk FROM refunded
    EXCEPT
    SELECT hd_demo_sk FROM returning
  ),

  filtered AS (
    SELECT
      f.hd_demo_sk,
      SUM(r.wr_return_amt) AS total_return_amt,
      COUNT(*) AS cnt_returns,
      CASE
        WHEN SUM(r.wr_return_amt) > 1000 THEN 'HIGH'
        WHEN SUM(r.wr_return_amt) > 500 THEN 'MEDIUM'
        ELSE 'LOW'
      END AS return_category,
      CONCAT('Potential:', hd.hd_buy_potential) AS buy_potential_desc,
      regexp_extract(hd.hd_buy_potential, '(high|medium|low)', 1) AS buy_potential_key
    FROM demo_exclusive f
    JOIN web_returns r
      ON r.wr_refunded_hdemo_sk = f.hd_demo_sk
    JOIN household_demographics hd
      ON hd.hd_demo_sk = f.hd_demo_sk
    WHERE NOT EXISTS (
      SELECT 1
      FROM web_returns wr2
      WHERE wr2.wr_returning_hdemo_sk = f.hd_demo_sk
        AND wr2.wr_return_amt > 2000
    )
    GROUP BY f.hd_demo_sk, hd.hd_buy_potential
  )
SELECT
  hd_demo_sk,
  total_return_amt,
  cnt_returns,
  return_category,
  buy_potential_desc,
  buy_potential_key
FROM filtered
ORDER BY total_return_amt DESC, hd_demo_sk
LIMIT 100
