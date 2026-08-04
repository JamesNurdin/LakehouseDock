WITH ws_data AS (
   SELECT
      ws.ws_order_number,
      ws.ws_sold_time_sk,
      ws.ws_bill_customer_sk,
      ws.ws_bill_hdemo_sk,
      ws.ws_ship_customer_sk,
      ws.ws_ship_hdemo_sk,
      ws.ws_web_page_sk,
      ws.ws_ship_mode_sk,
      ws.ws_warehouse_sk,
      ws.ws_ext_sales_price,
      ws.ws_net_profit
   FROM web_sales ws
   WHERE ws.ws_ext_sales_price > 0
),
cr_data AS (
   SELECT
      cr.cr_order_number,
      cr.cr_returned_time_sk,
      cr.cr_refunded_customer_sk,
      cr.cr_refunded_hdemo_sk,
      cr.cr_returning_customer_sk,
      cr.cr_returning_hdemo_sk,
      cr.cr_call_center_sk,
      cr.cr_ship_mode_sk,
      cr.cr_warehouse_sk,
      cr.cr_return_amount,
      cr.cr_fee
   FROM catalog_returns cr
   WHERE cr.cr_fee > 80
),
intersect_orders AS (
   SELECT ws_order_number AS order_id FROM ws_data
   INTERSECT
   SELECT cr_order_number FROM cr_data
),
full_join AS (
   SELECT
      ws.ws_order_number,
      cr.cr_order_number,
      ws.ws_ext_sales_price,
      cr.cr_return_amount
   FROM ws_data ws
   FULL OUTER JOIN cr_data cr
     ON ws.ws_order_number = cr.cr_order_number
)
SELECT
   cc.cc_division_name,
   wp.wp_web_page_id,
   sm.sm_type,
   ib.ib_upper_bound,
   SUM(fj.ws_ext_sales_price) AS total_sales,
   SUM(fj.cr_return_amount) AS total_returns,
   SUM(sr.sr_return_amt) AS total_store_returns,
   COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
   CASE WHEN SUM(fj.ws_ext_sales_price) - SUM(fj.cr_return_amount) > 50000 THEN 'PROFITABLE' ELSE 'MARGINAL' END AS profitability,
   lc.max_return_amount
FROM full_join fj
JOIN ws_data ws ON fj.ws_order_number = ws.ws_order_number
JOIN cr_data cr ON fj.cr_order_number = cr.cr_order_number
JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN store_returns sr
       ON sr.sr_customer_sk = c.c_customer_sk
      AND sr.sr_return_time_sk = td.t_time_sk
LEFT JOIN LATERAL (
   SELECT MAX(cr2.cr_return_amount) AS max_return_amount
   FROM catalog_returns cr2
   WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
) lc ON TRUE
WHERE wp.wp_rec_end_date = DATE '2000-09-02'
  AND ib.ib_upper_bound = 140000
  AND cc.cc_state = 'CA'
  AND EXISTS (
        SELECT 1 FROM catalog_returns cr3
        WHERE cr3.cr_returning_customer_sk = c.c_customer_sk
          AND cr3.cr_fee > 85
      )
GROUP BY
   cc.cc_division_name,
   wp.wp_web_page_id,
   sm.sm_type,
   ib.ib_upper_bound,
   lc.max_return_amount
ORDER BY total_sales DESC
LIMIT 100
