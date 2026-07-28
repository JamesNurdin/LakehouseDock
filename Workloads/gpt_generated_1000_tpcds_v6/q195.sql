WITH catalog_data AS (
   SELECT
      'catalog' AS source,
      td.t_meal_time AS meal_time,
      hd.hd_vehicle_count AS vehicle_cnt,
      ib.ib_lower_bound AS income_bracket,
      cr.cr_return_amount AS return_amount,
      cr.cr_net_loss AS net_loss,
      cr.cr_return_quantity AS qty,
      c.c_customer_id AS refunded_customer_id,
      ROW_NUMBER() OVER (PARTITION BY cr.cr_returned_date_sk ORDER BY cr.cr_return_amount DESC) AS rn
   FROM catalog_returns cr
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
   JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
web_data AS (
   SELECT
      'web' AS source,
      td_s.t_meal_time AS meal_time,
      hd_b.hd_vehicle_count AS vehicle_cnt,
      ib_b.ib_lower_bound AS income_bracket,
      wr.wr_return_amt AS return_amount,
      wr.wr_net_loss AS net_loss,
      wr.wr_return_quantity AS qty,
      c_bill.c_customer_id AS bill_customer_id,
      ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY wr.wr_return_amt DESC) AS rn
   FROM web_sales ws
   JOIN time_dim td_s ON ws.ws_sold_time_sk = td_s.t_time_sk
   JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
   JOIN household_demographics hd_b ON ws.ws_bill_hdemo_sk = hd_b.hd_demo_sk
   JOIN income_band ib_b ON hd_b.hd_income_band_sk = ib_b.ib_income_band_sk
   JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
   JOIN time_dim td_r ON wr.wr_returned_time_sk = td_r.t_time_sk
   JOIN customer c_ref ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
   JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
   JOIN income_band ib_ref ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
)
SELECT
    source,
    meal_time,
    vehicle_cnt,
    income_bracket,
    SUM(return_amount) AS total_return_amount,
    SUM(net_loss) AS total_net_loss,
    AVG(return_amount) AS avg_return_amount,
    COUNT(*) AS cnt_rows,
    ROW_NUMBER() OVER (PARTITION BY source ORDER BY SUM(return_amount) DESC) AS rank_by_return
FROM (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM web_data
) u
GROUP BY
    source,
    meal_time,
    vehicle_cnt,
    income_bracket
ORDER BY source, total_return_amount DESC
LIMIT 100
