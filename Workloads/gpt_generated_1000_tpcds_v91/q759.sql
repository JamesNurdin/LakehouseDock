WITH
  zip_prefixes AS (
    SELECT DISTINCT SUBSTR(ca_zip, 1, 2) AS zip_prefix
    FROM customer_address
    WHERE ca_zip IS NOT NULL
  ),
  risk_levels AS (
    SELECT * FROM (VALUES ('Low'), ('Medium'), ('High')) AS t(risk_level)
  ),
  store_types AS (
    SELECT * FROM (VALUES ('Urban'), ('Rural')) AS t(store_type)
  ),
  returns_agg AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      r.r_reason_desc,
      SUM(sr.sr_net_loss) AS total_net_loss,
      COUNT(*) AS return_cnt,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      SUBSTR(ca.ca_zip, 1, 2) AS zip_prefix
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2020
      AND REGEXP_LIKE(r.r_reason_desc, '(damage|missing|gift)')
      AND s.s_store_name LIKE '%Store%'
    GROUP BY s.s_store_sk, s.s_store_name, r.r_reason_desc,
             hd.hd_income_band_sk, ib.ib_lower_bound,
             ib.ib_upper_bound, SUBSTR(ca.ca_zip, 1, 2)
  )
SELECT
  ra.s_store_name,
  ra.r_reason_desc,
  ra.zip_prefix,
  ra.total_net_loss,
  ra.return_cnt,
  ra.ib_lower_bound,
  ra.ib_upper_bound,
  CONCAT('Store: ', ra.s_store_name) AS store_label,
  REGEXP_EXTRACT(ra.r_reason_desc, '(\\w+)') AS reason_keyword,
  SUM(ra.total_net_loss) OVER (PARTITION BY ra.zip_prefix) AS net_loss_by_zip,
  ROW_NUMBER() OVER (PARTITION BY ra.zip_prefix ORDER BY ra.total_net_loss DESC) AS zip_rank,
  (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_store_sk = ra.s_store_sk) AS total_store_returns,
  rl.risk_level,
  st.store_type
FROM returns_agg ra
CROSS JOIN zip_prefixes zp
CROSS JOIN risk_levels rl
CROSS JOIN store_types st
WHERE ra.zip_prefix = zp.zip_prefix
  AND rl.risk_level IN ('Low','Medium')
ORDER BY ra.total_net_loss DESC
LIMIT 100
