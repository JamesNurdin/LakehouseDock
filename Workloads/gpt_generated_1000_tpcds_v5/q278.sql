WITH cr_pre AS (
   SELECT
      hd.hd_income_band_sk,
      regexp_extract(hd.hd_buy_potential, '(\\d+)-(\\d+)', 1) AS lower_bound,
      regexp_extract(hd.hd_buy_potential, '(\\d+)-(\\d+)', 2) AS upper_bound,
      cr.cr_net_loss
   FROM catalog_returns cr
   JOIN household_demographics hd
     ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE regexp_like(hd.hd_buy_potential, '^[0-9]+-[0-9]+$')
     AND hd.hd_buy_potential LIKE '%-%'
),
cr_agg AS (
   SELECT
      hd_income_band_sk,
      lower_bound,
      upper_bound,
      SUM(cr_net_loss) AS total_cr_net_loss,
      COUNT(*) AS cr_return_cnt
   FROM cr_pre
   GROUP BY hd_income_band_sk, lower_bound, upper_bound
),
sr_pre AS (
   SELECT
      hd.hd_income_band_sk,
      regexp_extract(hd.hd_buy_potential, '(\\d+)-(\\d+)', 1) AS lower_bound,
      regexp_extract(hd.hd_buy_potential, '(\\d+)-(\\d+)', 2) AS upper_bound,
      sr.sr_net_loss
   FROM store_returns sr
   JOIN household_demographics hd
     ON sr.sr_hdemo_sk = hd.hd_demo_sk
   WHERE regexp_like(hd.hd_buy_potential, '^[0-9]+-[0-9]+$')
),
sr_agg AS (
   SELECT
      hd_income_band_sk,
      lower_bound,
      upper_bound,
      SUM(sr_net_loss) AS total_sr_net_loss,
      COUNT(*) AS sr_return_cnt
   FROM sr_pre
   GROUP BY hd_income_band_sk, lower_bound, upper_bound
)
SELECT
   cr.hd_income_band_sk,
   cr.lower_bound,
   cr.upper_bound,
   cr.total_cr_net_loss,
   sr.total_sr_net_loss,
   (cr.total_cr_net_loss + sr.total_sr_net_loss) AS combined_net_loss,
   CONCAT('Band ', CAST(cr.hd_income_band_sk AS VARCHAR), ': ', cr.lower_bound, '-', cr.upper_bound) AS band_label
FROM cr_agg cr
FULL OUTER JOIN sr_agg sr
  ON cr.hd_income_band_sk = sr.hd_income_band_sk
 AND cr.lower_bound = sr.lower_bound
 AND cr.upper_bound = sr.upper_bound
ORDER BY combined_net_loss DESC
LIMIT 100
