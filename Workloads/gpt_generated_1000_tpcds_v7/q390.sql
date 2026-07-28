WITH
  sales AS (
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_ship_hdemo_sk,
      cs.cs_ship_mode_sk,
      cs.cs_net_profit
    FROM catalog_sales cs
  ),
  returns AS (
    SELECT
      cr.cr_order_number,
      cr.cr_item_sk,
      cr.cr_refunded_hdemo_sk,
      cr.cr_returning_hdemo_sk,
      cr.cr_ship_mode_sk,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_reason_sk
    FROM catalog_returns cr
  )
SELECT
  i_cat.i_category,
  i_cat.i_class,
  sm_ship.sm_carrier,
  hd_bill.hd_income_band_sk AS bill_income_band,
  hd_ship.hd_income_band_sk AS ship_income_band,
  SUM(s.cs_net_profit) AS total_net_profit,
  SUM(r.cr_return_amount) AS total_return_amount,
  SUM(r.cr_return_quantity) AS total_return_qty,
  COUNT(DISTINCT s.cs_order_number) AS num_orders,
  COUNT(DISTINCT r.cr_order_number) AS num_returns
FROM sales s
JOIN returns r
  ON r.cr_order_number = s.cs_order_number
JOIN item i_cat
  ON s.cs_item_sk = i_cat.i_item_sk
JOIN item i_ret
  ON r.cr_item_sk = i_ret.i_item_sk
JOIN household_demographics hd_bill
  ON s.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
  ON s.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN household_demographics hd_refund
  ON r.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN household_demographics hd_returning
  ON r.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN ship_mode sm_ship
  ON s.cs_ship_mode_sk = sm_ship.sm_ship_mode_sk
JOIN ship_mode sm_ret
  ON r.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
JOIN reason r_reason
  ON r.cr_reason_sk = r_reason.r_reason_sk
GROUP BY
  i_cat.i_category,
  i_cat.i_class,
  sm_ship.sm_carrier,
  hd_bill.hd_income_band_sk,
  hd_ship.hd_income_band_sk
LIMIT 100
