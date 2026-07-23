SELECT
  s.s_store_name,
  sm.sm_type AS ship_mode_type,
  d.d_year,
  COUNT(DISTINCT c_bill.c_customer_sk) AS distinct_customers,
  SUM(cs.cs_net_paid) AS total_catalog_sales,
  SUM(ws.ws_net_paid) AS total_web_sales,
  SUM(cr.cr_return_amount) AS total_return_amount,
  AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount,
  AVG(ws.ws_ext_discount_amt) AS avg_web_discount
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib_bill ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN income_band ib_ship ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
-- Join Web Sales sharing the same date, ship mode and warehouse
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN customer c_ws_bill ON ws.ws_bill_customer_sk = c_ws_bill.c_customer_sk
JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN income_band ib_ws_bill ON hd_ws_bill.hd_income_band_sk = ib_ws_bill.ib_income_band_sk
JOIN customer c_ws_ship ON ws.ws_ship_customer_sk = c_ws_ship.c_customer_sk
JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
JOIN income_band ib_ws_ship ON hd_ws_ship.hd_income_band_sk = ib_ws_ship.ib_income_band_sk
-- Join Catalog Returns
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
JOIN warehouse w_ret ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN income_band ib_refunded ON hd_refunded.hd_income_band_sk = ib_refunded.ib_income_band_sk
JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN income_band ib_returning ON hd_returning.hd_income_band_sk = ib_returning.ib_income_band_sk
WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
  AND cs.cs_item_sk IN (
    SELECT DISTINCT cr2.cr_item_sk
    FROM catalog_returns cr2
    WHERE cr2.cr_return_amount > 500
  )
GROUP BY
  s.s_store_name,
  sm.sm_type,
  d.d_year
ORDER BY
  total_catalog_sales DESC
LIMIT 100
