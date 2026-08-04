WITH
  store_data AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk,
      sr.sr_ticket_number,
      sr.sr_return_amt,
      sr.sr_net_loss,
      d1.d_year,
      r1.r_reason_desc,
      hd1.hd_income_band_sk,
      ca1.ca_state
    FROM store_returns sr
    JOIN date_dim d1 ON sr.sr_returned_date_sk = d1.d_date_sk
    JOIN time_dim t1 ON sr.sr_return_time_sk = t1.t_time_sk
    JOIN reason r1 ON sr.sr_reason_sk = r1.r_reason_sk
    JOIN household_demographics hd1 ON sr.sr_hdemo_sk = hd1.hd_demo_sk
    JOIN customer_address ca1 ON sr.sr_addr_sk = ca1.ca_address_sk
    WHERE d1.d_year = 2001
  ),
  catalog_data AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_net_loss,
      cp.cp_department,
      cp.cp_catalog_page_number,
      d2.d_year,
      sm.sm_type,
      w.w_warehouse_name,
      r2.r_reason_desc AS cr_reason,
      hd2.hd_income_band_sk,
      ca2.ca_state
    FROM catalog_returns cr
    JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON cr.cr_returned_time_sk = t2.t_time_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
    JOIN household_demographics hd2 ON cr.cr_refunded_hdemo_sk = hd2.hd_demo_sk
    JOIN customer_address ca2 ON cr.cr_refunded_addr_sk = ca2.ca_address_sk
    WHERE cp.cp_department = 'Sports'
  ),
  web_data AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_returned_time_sk,
      wr.wr_order_number,
      wr.wr_return_amt,
      wp.wp_type,
      d3.d_year,
      r3.r_reason_desc AS wr_reason,
      hd3.hd_income_band_sk,
      ca3.ca_state
    FROM web_returns wr
    JOIN date_dim d3 ON wr.wr_returned_date_sk = d3.d_date_sk
    JOIN time_dim t3 ON wr.wr_returned_time_sk = t3.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r3 ON wr.wr_reason_sk = r3.r_reason_sk
    JOIN household_demographics hd3 ON wr.wr_refunded_hdemo_sk = hd3.hd_demo_sk
    JOIN customer_address ca3 ON wr.wr_refunded_addr_sk = ca3.ca_address_sk
    WHERE wp.wp_autogen_flag = 'N'
  ),
  promo_data AS (
    SELECT
      p.p_promo_id,
      p.p_promo_name,
      d4.d_year
    FROM promotion p
    JOIN date_dim d4 ON p.p_start_date_sk = d4.d_date_sk
    WHERE d4.d_year = 2001
  ),
  store_keys AS (
    SELECT sr.sr_ticket_number AS ticket
    FROM store_returns sr
  ),
  catalog_keys AS (
    SELECT cr.cr_order_number AS ticket
    FROM catalog_returns cr
  ),
  web_keys AS (
    SELECT wr.wr_order_number AS ticket
    FROM web_returns wr
  ),
  store_not_in_catalog AS (
    SELECT ticket FROM store_keys
    EXCEPT
    SELECT ticket FROM catalog_keys
  ),
  common_keys AS (
    SELECT ticket FROM store_keys
    INTERSECT
    SELECT ticket FROM web_keys
  ),
  aggregated AS (
    SELECT
      sd.d_year AS year,
      COUNT(DISTINCT sd.sr_ticket_number) AS store_return_cnt,
      SUM(sd.sr_return_amt) AS total_store_return_amt,
      COUNT(DISTINCT cd.cr_order_number) AS catalog_return_cnt,
      SUM(cd.cr_return_amount) AS total_catalog_return_amt,
      COUNT(DISTINCT wd.wr_order_number) AS web_return_cnt,
      SUM(wd.wr_return_amt) AS total_web_return_amt
    FROM store_data sd
    JOIN catalog_data cd ON sd.d_year = cd.d_year
    JOIN web_data wd ON sd.d_year = wd.d_year
    WHERE sd.r_reason_desc = 'Customer not satisfied'
    GROUP BY sd.d_year
  )
SELECT
  a.year,
  a.store_return_cnt,
  a.total_store_return_amt,
  a.catalog_return_cnt,
  a.total_catalog_return_amt,
  a.web_return_cnt,
  a.total_web_return_amt,
  CASE WHEN a.total_store_return_amt > 10000 THEN 'HIGH' ELSE 'LOW' END AS store_return_level,
  EXISTS (
    SELECT 1 FROM promo_data pd WHERE pd.p_promo_id = 'PROMO_001' AND pd.d_year = a.year
  ) AS promo_active,
  (SELECT COUNT(*) FROM store_not_in_catalog) AS store_not_in_catalog_cnt,
  (SELECT COUNT(*) FROM common_keys) AS common_key_cnt
FROM aggregated a
ORDER BY a.year DESC
LIMIT 100
