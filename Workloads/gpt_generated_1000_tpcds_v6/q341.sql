WITH
  cr_data AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_return_amount,
      cr.cr_net_loss,
      cc.cc_name,
      r.r_reason_desc,
      c_ref.c_customer_id,
      cd_ref.cd_purchase_estimate,
      hd_ref.hd_income_band_sk,
      ib_ref.ib_lower_bound,
      ib_ref.ib_upper_bound
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN income_band ib_ref ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
  ),
  ws_data AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      c_bill.c_customer_id AS bill_customer_id,
      cd_bill.cd_purchase_estimate AS bill_purchase_estimate,
      hd_bill.hd_income_band_sk AS bill_income_band_sk,
      ib_bill.ib_lower_bound AS bill_income_lb,
      ib_bill.ib_upper_bound AS bill_income_ub
    FROM web_sales ws
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib_bill ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
  ),
  wr_data AS (
    SELECT
      wr.wr_order_number,
      wr.wr_return_amt,
      wr.wr_net_loss,
      r_ret.r_reason_desc AS return_reason,
      c_ret.c_customer_id AS returned_customer_id,
      cd_ret.cd_purchase_estimate AS ret_purchase_estimate,
      hd_ret.hd_income_band_sk AS ret_income_band_sk,
      ib_ret.ib_lower_bound AS ret_income_lb,
      ib_ret.ib_upper_bound AS ret_income_ub
    FROM web_returns wr
    JOIN reason r_ret ON wr.wr_reason_sk = r_ret.r_reason_sk
    JOIN customer c_ret ON wr.wr_refunded_customer_sk = c_ret.c_customer_sk
    JOIN customer_demographics cd_ret ON wr.wr_refunded_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ret ON wr.wr_refunded_hdemo_sk = hd_ret.hd_demo_sk
    JOIN income_band ib_ret ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
  ),
  base AS (
    SELECT
      cr.c_customer_id AS refunded_customer_id,
      cr.r_reason_desc AS catalog_return_reason,
      SUM(cr.cr_return_amount) AS total_catalog_return_amount,
      SUM(cr.cr_net_loss) AS total_catalog_net_loss,
      COUNT(DISTINCT cr.cc_name) AS distinct_call_centers,
      ws.bill_customer_id,
      SUM(ws.ws_ext_sales_price) AS total_sales_price,
      SUM(ws.ws_net_profit) AS total_net_profit,
      COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
      SUM(wr.wr_return_amt) AS total_web_return_amount,
      SUM(wr.wr_net_loss) AS total_web_net_loss
    FROM cr_data cr
    LEFT JOIN ws_data ws ON cr.c_customer_id = ws.bill_customer_id
    LEFT JOIN wr_data wr ON cr.c_customer_id = wr.returned_customer_id
    GROUP BY
      cr.c_customer_id,
      cr.r_reason_desc,
      ws.bill_customer_id
    HAVING SUM(cr.cr_return_amount) > 1000
  )
SELECT
  refunded_customer_id,
  catalog_return_reason,
  total_catalog_return_amount,
  total_catalog_net_loss,
  distinct_call_centers,
  bill_customer_id,
  total_sales_price,
  total_net_profit,
  distinct_orders,
  total_web_return_amount,
  total_web_net_loss,
  ROW_NUMBER() OVER (PARTITION BY refunded_customer_id ORDER BY total_catalog_return_amount DESC) AS rn
FROM base
ORDER BY total_catalog_return_amount DESC
LIMIT 100
