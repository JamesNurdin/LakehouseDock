WITH
store_data AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_sold_time_sk,
    ss.ss_item_sk AS item_sk,
    ss.ss_customer_sk,
    c.c_customer_sk AS c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    ss.ss_quantity,
    ss.ss_net_paid,
    ss.ss_net_profit,
    td.t_hour,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ca.ca_state,
    ca.ca_country
  FROM store_sales ss
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
),
catalog_data AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_returned_time_sk,
    cr.cr_item_sk AS item_sk,
    cr.cr_refunded_customer_sk AS c_customer_sk,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_net_loss,
    td_cr.t_hour AS return_hour,
    i_cr.i_category AS return_category,
    i_cr.i_brand AS return_brand,
    r.r_reason_desc AS reason_desc,
    sm.sm_type AS ship_type,
    ca_cr.ca_state AS return_state,
    ca_cr.ca_country AS return_country,
    ib_cr.ib_lower_bound AS return_income_lower,
    ib_cr.ib_upper_bound AS return_income_upper,
    c_cr.c_first_name,
    c_cr.c_last_name
  FROM catalog_returns cr
  JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
  JOIN item i_cr ON cr.cr_item_sk = i_cr.i_item_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_address ca_cr ON cr.cr_refunded_addr_sk = ca_cr.ca_address_sk
  JOIN household_demographics hd_cr ON cr.cr_refunded_hdemo_sk = hd_cr.hd_demo_sk
  JOIN income_band ib_cr ON hd_cr.hd_income_band_sk = ib_cr.ib_income_band_sk
  JOIN customer c_cr ON cr.cr_refunded_customer_sk = c_cr.c_customer_sk
),
web_data AS (
  SELECT
    wr.wr_returned_date_sk,
    wr.wr_returned_time_sk,
    wr.wr_item_sk AS item_sk,
    wr.wr_refunded_customer_sk AS c_customer_sk,
    wr.wr_return_amt,
    wr.wr_return_tax,
    wr.wr_net_loss,
    td_wr.t_hour AS web_return_hour,
    i_wr.i_category AS web_return_category,
    i_wr.i_brand AS web_return_brand,
    r_wr.r_reason_desc AS web_reason_desc,
    wp.wp_url,
    ca_wr.ca_state AS web_state,
    ca_wr.ca_country AS web_country,
    ib_wr.ib_lower_bound AS web_income_lower,
    ib_wr.ib_upper_bound AS web_income_upper,
    c_wr.c_first_name,
    c_wr.c_last_name
  FROM web_returns wr
  JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
  JOIN item i_wr ON wr.wr_item_sk = i_wr.i_item_sk
  JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN customer_address ca_wr ON wr.wr_refunded_addr_sk = ca_wr.ca_address_sk
  JOIN household_demographics hd_wr ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
  JOIN income_band ib_wr ON hd_wr.hd_income_band_sk = ib_wr.ib_income_band_sk
  JOIN customer c_wr ON wr.wr_refunded_customer_sk = c_wr.c_customer_sk
)
SELECT
  COALESCE(sd.c_first_name, cd.c_first_name, wd.c_first_name) AS first_name,
  COALESCE(sd.c_last_name, cd.c_last_name, wd.c_last_name) AS last_name,
  COALESCE(sd.i_category, cd.return_category, wd.web_return_category) AS item_category,
  COALESCE(sd.i_brand, cd.return_brand, wd.web_return_brand) AS item_brand,
  COALESCE(sd.t_hour, cd.return_hour, wd.web_return_hour) AS hour_of_day,
  COALESCE(sd.ca_state, cd.return_state, wd.web_state) AS state,
  COALESCE(sd.ca_country, cd.return_country, wd.web_country) AS country,
  sd.ss_net_paid,
  sd.ss_net_profit,
  cd.cr_return_amount,
  cd.cr_return_tax,
  cd.cr_net_loss,
  wd.wr_return_amt,
  wd.wr_return_tax,
  wd.wr_net_loss,
  RANK() OVER (
    PARTITION BY COALESCE(sd.c_customer_sk, cd.c_customer_sk, wd.c_customer_sk)
    ORDER BY COALESCE(sd.ss_net_paid, 0) DESC
  ) AS sales_rank,
  AVG(sd.ss_net_profit) OVER (
    PARTITION BY COALESCE(sd.c_customer_sk, cd.c_customer_sk, wd.c_customer_sk)
    ORDER BY COALESCE(sd.t_hour, 0)
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS profit_moving_avg,
  (
    SELECT AVG(cr2.cr_return_amount)
    FROM catalog_returns cr2
    WHERE cr2.cr_item_sk = COALESCE(sd.item_sk, cd.item_sk, wd.item_sk)
  ) AS avg_item_return_amount,
  cd.reason_desc,
  cd.ship_type
FROM store_data sd
FULL OUTER JOIN catalog_data cd
  ON sd.c_customer_sk = cd.c_customer_sk
FULL OUTER JOIN web_data wd
  ON COALESCE(sd.c_customer_sk, cd.c_customer_sk) = wd.c_customer_sk
WHERE
  sd.i_category = 'fragrances'
  AND sd.i_brand = 'eseoughtable'
  AND sd.t_hour BETWEEN 8 AND 18
  AND sd.ib_lower_bound >= 50000
  AND cd.reason_desc = 'Lost my job'
  AND cd.ship_type = 'AIR'
LIMIT 100
