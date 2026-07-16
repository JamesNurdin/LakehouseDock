WITH store_ret AS (
  SELECT
    d.d_year AS year,
    hd.hd_income_band_sk AS income_band,
    SUM(sr.sr_net_loss) AS store_net_loss,
    AVG(sr.sr_return_quantity) AS avg_store_qty,
    COUNT(*) AS store_return_cnt
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE d.d_current_year = 'Y'
    AND hd.hd_buy_potential = 'HIGH'
    AND s.s_state = 'CA'
  GROUP BY d.d_year, hd.hd_income_band_sk
),
web_ret AS (
  SELECT
    d.d_year AS year,
    hd.hd_income_band_sk AS income_band,
    SUM(wr.wr_net_loss) AS web_net_loss,
    AVG(wr.wr_return_quantity) AS avg_web_qty,
    COUNT(*) AS web_return_cnt
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE d.d_current_year = 'Y'
    AND hd.hd_buy_potential = 'HIGH'
    AND wp.wp_type = 'content'
  GROUP BY d.d_year, hd.hd_income_band_sk
)
SELECT
  COALESCE(sr.year, wr.year) AS year,
  COALESCE(sr.income_band, wr.income_band) AS income_band,
  COALESCE(sr.store_net_loss, 0) + COALESCE(wr.web_net_loss, 0) AS total_net_loss,
  (COALESCE(sr.avg_store_qty, 0) * COALESCE(sr.store_return_cnt, 0) +
   COALESCE(wr.avg_web_qty, 0) * COALESCE(wr.web_return_cnt, 0)) /
    NULLIF(COALESCE(sr.store_return_cnt, 0) + COALESCE(wr.web_return_cnt, 0), 0) AS weighted_avg_return_qty,
  RANK() OVER (ORDER BY (COALESCE(sr.store_net_loss, 0) + COALESCE(wr.web_net_loss, 0)) DESC) AS loss_rank
FROM store_ret sr
FULL OUTER JOIN web_ret wr
  ON sr.year = wr.year AND sr.income_band = wr.income_band
ORDER BY total_net_loss DESC
LIMIT 50
