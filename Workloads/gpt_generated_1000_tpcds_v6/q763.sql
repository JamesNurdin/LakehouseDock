WITH store_loss AS (
  SELECT
    d.d_date AS return_date,
    'store' AS channel,
    SUM(sr.sr_net_loss) AS total_net_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  WHERE hd.hd_income_band_sk = 5
    AND d.d_year = 2001
  GROUP BY d.d_date
),
web_loss AS (
  SELECT
    d.d_date AS return_date,
    'web' AS channel,
    SUM(wr.wr_net_loss) AS total_net_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE hd.hd_buy_potential = '>10000'
    AND wp.wp_char_count > 4000
    AND d.d_year = 2001
  GROUP BY d.d_date
)
SELECT DISTINCT
  return_date,
  channel,
  total_net_loss
FROM (
  SELECT * FROM store_loss
  UNION ALL
  SELECT * FROM web_loss
) AS combined
ORDER BY return_date DESC, channel
LIMIT 100
