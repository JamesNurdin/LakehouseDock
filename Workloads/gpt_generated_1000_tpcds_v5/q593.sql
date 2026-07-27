SELECT
    sm.sm_ship_mode_id,
    ib_bill.ib_lower_bound AS bill_income_lower,
    ib_bill.ib_upper_bound AS bill_income_upper,
    ib_ship.ib_lower_bound AS ship_income_lower,
    ib_ship.ib_upper_bound AS ship_income_upper,
    ib_ret.ib_lower_bound AS ret_income_lower,
    ib_ret.ib_upper_bound AS ret_income_upper,
    wp.wp_type,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT wr.wr_order_number) AS return_orders_cnt
FROM catalog_sales cs
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
  ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_returns wr
  ON wr.wr_refunded_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ret
  ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN income_band ib_bill
  ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
JOIN income_band ib_ship
  ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
JOIN income_band ib_ret
  ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
WHERE sm.sm_type = 'AIR'
  AND wp.wp_type = 'PRODUCT'
GROUP BY
    sm.sm_ship_mode_id,
    ib_bill.ib_lower_bound,
    ib_bill.ib_upper_bound,
    ib_ship.ib_lower_bound,
    ib_ship.ib_upper_bound,
    ib_ret.ib_lower_bound,
    ib_ret.ib_upper_bound,
    wp.wp_type
ORDER BY total_net_profit DESC
LIMIT 100
