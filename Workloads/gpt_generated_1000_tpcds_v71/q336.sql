WITH
  catalog_data AS (
    SELECT
      'catalog' AS source_type,
      CAST(NULL AS VARCHAR) AS store_id,
      cp.cp_catalog_number AS catalog_number,
      d_cr.d_year AS year,
      SUM(cr.cr_net_loss) AS total_net_loss,
      COUNT(*) AS return_cnt,
      CASE WHEN sm.sm_code = 'AIR' THEN SUM(cr.cr_return_amount) ELSE 0 END AS air_return_amount,
      CAST(NULL AS DECIMAL(7,2)) AS ca_return_amount,
      (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) AS avg_net_loss_all
    FROM
      catalog_returns cr
      JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
      JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
      JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
      JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
      JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
      JOIN inventory inv ON inv.inv_date_sk = d_cr.d_date_sk
      JOIN web_site ws ON ws.web_open_date_sk = d_cr.d_date_sk
    GROUP BY
      cp.cp_catalog_number,
      d_cr.d_year,
      sm.sm_code
  ),
  store_data AS (
    SELECT
      'store' AS source_type,
      s.s_store_id AS store_id,
      CAST(NULL AS INTEGER) AS catalog_number,
      d_sr.d_year AS year,
      SUM(sr.sr_net_loss) AS total_net_loss,
      COUNT(*) AS return_cnt,
      CAST(NULL AS DECIMAL(7,2)) AS air_return_amount,
      CASE WHEN s.s_state = 'CA' THEN SUM(sr.sr_return_amt) ELSE 0 END AS ca_return_amount,
      (SELECT AVG(sr2.sr_net_loss) FROM store_returns sr2) AS avg_net_loss_all
    FROM
      store_returns sr
      JOIN store s ON sr.sr_store_sk = s.s_store_sk
      JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
      JOIN customer c_ret ON sr.sr_customer_sk = c_ret.c_customer_sk
      JOIN customer_demographics cd_ret ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
      JOIN household_demographics hd_ret ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
      JOIN inventory inv2 ON inv2.inv_date_sk = d_sr.d_date_sk
      JOIN web_site ws2 ON ws2.web_close_date_sk = d_sr.d_date_sk
    GROUP BY
      s.s_store_id,
      d_sr.d_year,
      s.s_state
  ),
  combined AS (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM store_data
  )
SELECT
  source_type,
  store_id,
  catalog_number,
  year,
  total_net_loss,
  return_cnt,
  air_return_amount,
  ca_return_amount,
  avg_net_loss_all,
  ROW_NUMBER() OVER (PARTITION BY source_type ORDER BY total_net_loss DESC) AS loss_rank
FROM combined
ORDER BY source_type, loss_rank
