WITH
  store_data AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_item_sk,
      sr.sr_return_quantity,
      sr.sr_net_loss,
      d.d_year,
      i.i_brand,
      i.i_category,
      c.c_customer_id,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      p.p_promo_id,
      p.p_channel_dmail,
      p.p_channel_catalog
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN promotion p
      ON p.p_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_promo
      ON p.p_start_date_sk = d_promo.d_date_sk
    WHERE d.d_fy_year = 1914
      AND i.i_current_price BETWEEN 10 AND 100
      AND (p.p_channel_dmail = 'Y' OR p.p_channel_dmail IS NULL)
  ),
  catalog_data AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_item_sk,
      cr.cr_return_quantity,
      cr.cr_net_loss,
      d.d_year,
      i.i_brand,
      i.i_category,
      cc.cc_name,
      cp.cp_department,
      w.w_warehouse_name,
      c_ref.c_customer_id AS refunded_customer_id,
      cd_ref.cd_gender AS refunded_gender,
      hd_ref.hd_income_band_sk AS refunded_income_band,
      ib_ref.ib_lower_bound AS refunded_income_low,
      ib_ref.ib_upper_bound AS refunded_income_high
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer c_ref
      ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer_demographics cd_ref
      ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref
      ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN income_band ib_ref
      ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
    WHERE d.d_day_name = 'Monday'
      AND cp.cp_type = 'A'
      AND cc.cc_gmt_offset = -5.00
  ),
  web_data AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_item_sk,
      wr.wr_return_quantity,
      wr.wr_net_loss,
      d.d_year,
      i.i_brand,
      i.i_category,
      c_ref.c_customer_id AS refunded_customer_id,
      cd_ref.cd_gender AS refunded_gender,
      hd_ref.hd_income_band_sk AS refunded_income_band,
      ib_ref.ib_lower_bound AS refunded_income_low,
      ib_ref.ib_upper_bound AS refunded_income_high
    FROM web_returns wr
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
      ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c_ref
      ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer_demographics cd_ref
      ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref
      ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN income_band ib_ref
      ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
    WHERE d.d_fy_year = 1912
      AND i.i_color = 'Red'
      AND wr.wr_return_quantity > 1
  )
SELECT
  year,
  brand,
  category,
  SUM(total_net_loss) AS total_net_loss,
  COUNT(*) AS txn_count,
  AVG(return_quantity) AS avg_quantity
FROM (
  SELECT
    d_year AS year,
    i_brand AS brand,
    i_category AS category,
    sr_net_loss AS total_net_loss,
    sr_return_quantity AS return_quantity
  FROM store_data
  UNION ALL
  SELECT
    d_year,
    i_brand,
    i_category,
    cr_net_loss,
    cr_return_quantity
  FROM catalog_data
  UNION ALL
  SELECT
    d_year,
    i_brand,
    i_category,
    wr_net_loss,
    wr_return_quantity
  FROM web_data
) AS all_returns
GROUP BY year, brand, category
HAVING SUM(total_net_loss) > 1000
ORDER BY total_net_loss DESC, year
