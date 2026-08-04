WITH base AS (
  SELECT
    d.d_year,
    i.i_brand,
    i.i_category,
    sm.sm_type,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_order_number,
    wr.wr_return_amt,
    wr.wr_return_tax,
    wr.wr_order_number,
    ca.ca_state,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    r.r_reason_desc,
    ws.web_state
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN income_band ib ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  LEFT JOIN web_returns wr
    ON cr.cr_returned_date_sk = wr.wr_returned_date_sk
   AND cr.cr_returned_time_sk = wr.wr_returned_time_sk
   AND cr.cr_item_sk = wr.wr_item_sk
  LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_site ws ON wp.wp_creation_date_sk = ws.web_open_date_sk
  WHERE d.d_year = 2001
    AND i.i_brand = 'exportischolar #2'
    AND ca.ca_state = 'CA'
    AND ib.ib_lower_bound >= 20000
    AND sm.sm_type = 'AIR'
    AND i.i_current_price > (
          SELECT MAX(i2.i_current_price)
          FROM item i2
          WHERE i2.i_brand = 'edu packimporto #2'
        )
),
second AS (
  SELECT
    d.d_year,
    i.i_brand,
    i.i_category,
    sm.sm_type,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    MIN(ib.ib_lower_bound) AS min_income,
    MAX(ib.ib_upper_bound) AS max_income
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN income_band ib ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  LEFT JOIN web_returns wr
    ON cr.cr_returned_date_sk = wr.wr_returned_date_sk
   AND cr.cr_returned_time_sk = wr.wr_returned_time_sk
   AND cr.cr_item_sk = wr.wr_item_sk
  LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_site ws ON wp.wp_creation_date_sk = ws.web_open_date_sk
  WHERE d.d_year = 2002
    AND i.i_brand = 'importobrand #6'
    AND ca.ca_state = 'TX'
    AND ib.ib_lower_bound >= 30000
    AND sm.sm_type = 'RAIL'
  GROUP BY d.d_year, i.i_brand, i.i_category, sm.sm_type
)
SELECT
  d_year,
  i_brand,
  i_category,
  sm_type,
  SUM(cr_return_amount) AS total_catalog_return_amount,
  SUM(wr_return_amt) AS total_web_return_amount,
  COUNT(DISTINCT cr_order_number) AS catalog_orders,
  COUNT(DISTINCT wr_order_number) AS web_orders,
  MIN(ib_lower_bound) AS min_income,
  MAX(ib_upper_bound) AS max_income
FROM base
GROUP BY d_year, i_brand, i_category, sm_type
HAVING SUM(cr_return_amount) > 1000
EXCEPT
SELECT
  d_year,
  i_brand,
  i_category,
  sm_type,
  total_catalog_return_amount,
  total_web_return_amount,
  catalog_orders,
  web_orders,
  min_income,
  max_income
FROM second
ORDER BY total_catalog_return_amount DESC
LIMIT 100
