WITH sr AS (
  SELECT
    sr.sr_ticket_number,
    sr.sr_return_amt,
    sr.sr_return_quantity,
    date_dim.d_year,
    date_dim.d_date,
    store.s_store_name,
    item.i_category,
    reason.r_reason_desc,
    time_dim.t_hour,
    call_center.cc_name,
    customer.c_first_name,
    household_demographics.hd_income_band_sk,
    income_band.ib_lower_bound,
    ROW_NUMBER() OVER (PARTITION BY store.s_store_sk ORDER BY sr.sr_return_amt DESC) AS rn_store
  FROM store_returns sr
  JOIN date_dim ON sr.sr_returned_date_sk = date_dim.d_date_sk
  JOIN time_dim ON sr.sr_return_time_sk = time_dim.t_time_sk
  JOIN store ON sr.sr_store_sk = store.s_store_sk
  JOIN item ON sr.sr_item_sk = item.i_item_sk
  JOIN reason ON sr.sr_reason_sk = reason.r_reason_sk
  JOIN household_demographics ON sr.sr_hdemo_sk = household_demographics.hd_demo_sk
  JOIN income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
  JOIN customer ON sr.sr_customer_sk = customer.c_customer_sk
  LEFT JOIN call_center ON call_center.cc_closed_date_sk = date_dim.d_date_sk
  WHERE date_dim.d_year = 2001
    AND date_dim.d_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
    AND sr.sr_return_amt > 100
    AND item.i_current_price BETWEEN 10 AND 100
    AND store.s_floor_space > 2000
    AND income_band.ib_upper_bound <= 50000
    AND time_dim.t_hour BETWEEN 9 AND 17
    AND customer.c_birth_year = 1965
),
wr AS (
  SELECT
    wr.wr_order_number,
    wr.wr_return_amt,
    wr.wr_return_quantity,
    date_dim.d_year,
    date_dim.d_date,
    web_page.wp_url,
    item.i_category,
    reason.r_reason_desc,
    time_dim.t_hour,
    call_center.cc_name,
    customer.c_first_name,
    household_demographics.hd_income_band_sk,
    income_band.ib_lower_bound,
    ROW_NUMBER() OVER (PARTITION BY web_page.wp_web_page_sk ORDER BY wr.wr_return_amt DESC) AS rn_page
  FROM web_returns wr
  JOIN date_dim ON wr.wr_returned_date_sk = date_dim.d_date_sk
  JOIN time_dim ON wr.wr_returned_time_sk = time_dim.t_time_sk
  JOIN item ON wr.wr_item_sk = item.i_item_sk
  JOIN reason ON wr.wr_reason_sk = reason.r_reason_sk
  JOIN household_demographics ON wr.wr_refunded_hdemo_sk = household_demographics.hd_demo_sk
  JOIN income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
  JOIN customer ON wr.wr_refunded_customer_sk = customer.c_customer_sk
  LEFT JOIN web_page ON wr.wr_web_page_sk = web_page.wp_web_page_sk
  LEFT JOIN call_center ON call_center.cc_closed_date_sk = date_dim.d_date_sk
  WHERE date_dim.d_year = 2001
    AND date_dim.d_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
    AND wr.wr_return_amt > 100
    AND item.i_current_price BETWEEN 20 AND 150
    AND web_page.wp_link_count > 5
    AND income_band.ib_lower_bound >= 20000
    AND time_dim.t_hour BETWEEN 9 AND 17
    AND customer.c_birth_year = 1965
)
SELECT
  return_id,
  return_amt,
  d_year,
  location_name,
  i_category,
  r_reason_desc,
  t_hour,
  manager_name,
  first_name,
  hd_income_band_sk,
  ib_lower_bound,
  rank_within_group
FROM (
  SELECT
    sr_ticket_number AS return_id,
    sr_return_amt AS return_amt,
    d_year,
    s_store_name AS location_name,
    i_category,
    r_reason_desc,
    t_hour,
    cc_name AS manager_name,
    c_first_name AS first_name,
    hd_income_band_sk,
    ib_lower_bound,
    rn_store AS rank_within_group
  FROM sr
  UNION ALL
  SELECT
    wr_order_number AS return_id,
    wr_return_amt AS return_amt,
    d_year,
    wp_url AS location_name,
    i_category,
    r_reason_desc,
    t_hour,
    cc_name AS manager_name,
    c_first_name AS first_name,
    hd_income_band_sk,
    ib_lower_bound,
    rn_page AS rank_within_group
  FROM wr
) combined
ORDER BY d_year DESC, rank_within_group ASC
LIMIT 100
