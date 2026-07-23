WITH
  store_agg AS (
    SELECT
      i.i_item_sk,
      i.i_category,
      d_sr.d_year AS return_year,
      r_sr.r_reason_desc,
      SUM(sr.sr_return_quantity) AS total_store_qty,
      SUM(sr.sr_net_loss) AS total_store_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
    GROUP BY
      i.i_item_sk,
      i.i_category,
      d_sr.d_year,
      r_sr.r_reason_desc
  ),
  catalog_agg AS (
    SELECT
      i.i_item_sk,
      i.i_category,
      d_cr.d_year AS return_year,
      r_cr.r_reason_desc,
      cc.cc_name,
      sm.sm_type,
      w.w_warehouse_name,
      SUM(cr.cr_return_quantity) AS total_catalog_qty,
      SUM(cr.cr_net_loss) AS total_catalog_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    GROUP BY
      i.i_item_sk,
      i.i_category,
      d_cr.d_year,
      r_cr.r_reason_desc,
      cc.cc_name,
      sm.sm_type,
      w.w_warehouse_name
  ),
  web_agg AS (
    SELECT
      i.i_item_sk,
      i.i_category,
      d_wr.d_year AS return_year,
      r_wr.r_reason_desc,
      wp.wp_type,
      SUM(wr.wr_return_quantity) AS total_web_qty,
      SUM(wr.wr_net_loss) AS total_web_loss
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c_wr_ref ON wr.wr_refunded_customer_sk = c_wr_ref.c_customer_sk
    JOIN customer c_wr_ret ON wr.wr_returning_customer_sk = c_wr_ret.c_customer_sk
    GROUP BY
      i.i_item_sk,
      i.i_category,
      d_wr.d_year,
      r_wr.r_reason_desc,
      wp.wp_type
  )
SELECT
  COALESCE(sa.i_category, ca.i_category, wa.i_category) AS category,
  COALESCE(sa.return_year, ca.return_year, wa.return_year) AS year,
  COALESCE(sa.r_reason_desc, ca.r_reason_desc, wa.r_reason_desc) AS reason,
  SUM(sa.total_store_qty) AS store_qty,
  SUM(sa.total_store_loss) AS store_loss,
  SUM(ca.total_catalog_qty) AS catalog_qty,
  SUM(ca.total_catalog_loss) AS catalog_loss,
  SUM(wa.total_web_qty) AS web_qty,
  SUM(wa.total_web_loss) AS web_loss,
  MAX(ca.cc_name) AS call_center_name,
  MAX(ca.sm_type) AS ship_mode_type,
  MAX(ca.w_warehouse_name) AS warehouse_name,
  MAX(wa.wp_type) AS web_page_type
FROM store_agg sa
FULL OUTER JOIN catalog_agg ca
  ON sa.i_item_sk = ca.i_item_sk
 AND sa.return_year = ca.return_year
 AND sa.r_reason_desc = ca.r_reason_desc
FULL OUTER JOIN web_agg wa
  ON COALESCE(sa.i_item_sk, ca.i_item_sk) = wa.i_item_sk
 AND COALESCE(sa.return_year, ca.return_year) = wa.return_year
 AND COALESCE(sa.r_reason_desc, ca.r_reason_desc) = wa.r_reason_desc
GROUP BY
  COALESCE(sa.i_category, ca.i_category, wa.i_category),
  COALESCE(sa.return_year, ca.return_year, wa.return_year),
  COALESCE(sa.r_reason_desc, ca.r_reason_desc, wa.r_reason_desc)
HAVING
  SUM(COALESCE(sa.total_store_loss, 0) + COALESCE(ca.total_catalog_loss, 0) + COALESCE(wa.total_web_loss, 0)) > 1000
ORDER BY
  year DESC,
  category,
  reason
LIMIT 100
