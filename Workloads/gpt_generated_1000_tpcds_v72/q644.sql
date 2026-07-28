WITH
  catalog_agg AS (
    SELECT
      'catalog' AS channel,
      cc.cc_name AS entity_name,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cr.cr_return_amount) AS total_returns,
      COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_demographics cd_bill
      ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN tpcds.household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN tpcds.customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.reason r_cr
      ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN tpcds.inventory inv
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.income_band ib
      ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cc.cc_state = 'CA'
      AND cr.cr_return_amount > 500
      AND ib.ib_lower_bound >= 100000
    GROUP BY cc.cc_name
  ),
  store_agg AS (
    SELECT
      'store' AS channel,
      s.s_store_name AS entity_name,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(sr.sr_return_amt) AS total_returns,
      COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt
    FROM tpcds.store_sales ss
    JOIN tpcds.store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.customer_demographics cd_ss
      ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN tpcds.household_demographics hd_ss
      ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN tpcds.customer_address ca_ss
      ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN tpcds.store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.reason r_sr
      ON sr.sr_reason_sk = r_sr.r_reason_sk
    WHERE s.s_state = 'TX'
      AND ss.ss_quantity > 10
      AND hd_ss.hd_income_band_sk IN (SELECT ib_income_band_sk FROM tpcds.income_band WHERE ib_upper_bound <= 200000)
    GROUP BY s.s_store_name
  ),
  web_agg AS (
    SELECT
      'web' AS channel,
      CAST(ws.ws_web_site_sk AS VARCHAR) AS entity_name,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(wr.wr_return_amt) AS total_returns,
      COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM tpcds.web_sales ws
    JOIN tpcds.warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_demographics cd_ws
      ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
    JOIN tpcds.household_demographics hd_ws
      ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN tpcds.customer_address ca_ws
      ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
    JOIN tpcds.web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.reason r_wr
      ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE ws.ws_quantity >= 5
      AND w.w_state = 'CA'
      AND cd_ws.cd_marital_status = 'M'
    GROUP BY ws.ws_web_site_sk
  ),
  combined AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
  )
SELECT
  channel,
  entity_name,
  total_sales,
  total_returns,
  order_cnt,
  SUM(total_sales) OVER () AS grand_total_sales,
  RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM combined
ORDER BY total_sales DESC
LIMIT 100
