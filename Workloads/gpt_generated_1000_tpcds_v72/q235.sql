WITH base AS (
  SELECT
    cc.cc_name AS cc_name,
    sm.sm_type AS sm_type,
    cp.cp_department AS cp_department,
    cs.cs_order_number AS cs_order_number,
    cs.cs_ext_sales_price AS cs_ext_sales_price,
    ss.ss_ticket_number AS ss_ticket_number,
    ss.ss_ext_sales_price AS ss_ext_sales_price,
    sr.sr_ticket_number AS sr_ticket_number,
    sr.sr_return_amt AS sr_return_amt,
    ib.ib_upper_bound AS ib_upper_bound
  FROM tpcds.catalog_sales cs
  INNER JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  INNER JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  INNER JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  INNER JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  INNER JOIN tpcds.customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  INNER JOIN tpcds.customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  INNER JOIN tpcds.household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  INNER JOIN tpcds.customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
  INNER JOIN tpcds.customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
  INNER JOIN tpcds.household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  INNER JOIN tpcds.store_sales ss ON ss.ss_customer_sk = c_bill.c_customer_sk
  INNER JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  INNER JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
  INNER JOIN tpcds.income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
  cc_name,
  sm_type,
  cp_department,
  COUNT(DISTINCT cs_order_number)            AS num_catalog_orders,
  SUM(cs_ext_sales_price)                    AS total_catalog_sales,
  COUNT(DISTINCT ss_ticket_number)           AS num_store_sales,
  SUM(ss_ext_sales_price)                    AS total_store_sales,
  COUNT(DISTINCT sr_ticket_number)           AS num_returns,
  SUM(sr_return_amt)                         AS total_return_amount,
  AVG(ib_upper_bound)                        AS avg_income_upper_bound
FROM base
GROUP BY
  cc_name,
  sm_type,
  cp_department
ORDER BY total_catalog_sales DESC
LIMIT 100
