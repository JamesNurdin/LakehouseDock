WITH
  -- Sub‑query A: store returns joined to store sales and related dimensions
  store_path AS (
    SELECT
      'StorePath' AS category,
      (sr.sr_return_amt - ss.ss_sales_price) AS net_amount,
      sr.sr_ticket_number AS key_id
    FROM store_returns sr
    JOIN store_sales ss
      ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t_sr
      ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN time_dim t_ss
      ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT OUTER JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE NOT EXISTS (
      SELECT 1 FROM web_returns wr
      WHERE wr.wr_returning_addr_sk = sr.sr_addr_sk
    )
  ),

  -- Sub‑query B part 1: catalog returns joined to its dimensions
  catalog_part AS (
    SELECT
      'CatalogPath' AS category,
      cr.cr_return_amount AS net_amount,
      cr.cr_order_number AS key_id
    FROM catalog_returns cr
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t_cr
      ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN household_demographics hd_ref
      ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret
      ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    LEFT OUTER JOIN customer_address ca_ref
      ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    LEFT OUTER JOIN customer_address ca_ret
      ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN income_band ib_ref
      ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
    JOIN income_band ib_ret
      ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
  ),

  -- Sub‑query B part 2: web returns joined to its dimensions
  web_part AS (
    SELECT
      'WebPath' AS category,
      wr.wr_return_amt AS net_amount,
      wr.wr_order_number AS key_id
    FROM web_returns wr
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim t_wr
      ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN household_demographics hd_ref
      ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret
      ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    LEFT OUTER JOIN customer_address ca_ref
      ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    LEFT OUTER JOIN customer_address ca_ret
      ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN income_band ib_ref
      ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
    JOIN income_band ib_ret
      ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
  ),

  -- Combine catalog and web parts with a set operation
  combined_others AS (
    SELECT * FROM catalog_part
    UNION ALL
    SELECT * FROM web_part
  )

SELECT
  final.category,
  SUM(final.net_amount) AS total_net_amount,
  COUNT(*) AS cnt,
  CASE WHEN SUM(final.net_amount) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
FROM (
  SELECT * FROM store_path
  UNION ALL
  SELECT * FROM combined_others
) AS final
GROUP BY final.category
ORDER BY total_net_amount DESC
LIMIT 100
