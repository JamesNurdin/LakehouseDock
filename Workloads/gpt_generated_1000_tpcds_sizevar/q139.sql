WITH
  catalog AS (
    SELECT
      cp.cp_department,
      sm.sm_type,
      r_cr.r_reason_desc AS catalog_return_reason,
      cs.cs_order_number,
      cs.cs_net_profit,
      cr.cr_net_loss
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk
                         AND cr.cr_order_number = cs.cs_order_number
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    WHERE cp.cp_department = 'Books'
      AND sm.sm_type = 'AIR'
      AND ca_bill.ca_state = 'CA'
      AND hd_bill.hd_income_band_sk = 5
      AND cr.cr_returned_date_sk = 2450050
  ),
  store AS (
    SELECT
      s.s_store_name,
      s.s_state,
      r_sr.r_reason_desc AS store_return_reason,
      sr.sr_net_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    WHERE s.s_state = 'TX'
      AND r_sr.r_reason_desc LIKE '%price%'
  ),
  web AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_net_profit,
      wr.wr_net_loss,
      r_wr.r_reason_desc AS web_return_reason
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN customer_address ca_ws ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
    JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
                       AND wr.wr_order_number = ws.ws_order_number
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND sm.sm_type = 'AIR'
      AND wr.wr_returned_date_sk = 2450055
  )
SELECT
  cat.cp_department,
  cat.sm_type,
  cat.catalog_return_reason,
  st.s_store_name,
  wr.web_return_reason,
  COUNT(DISTINCT cat.cs_order_number) AS order_cnt,
  SUM(cat.cs_net_profit) AS catalog_sales_profit,
  SUM(cat.cr_net_loss) AS catalog_returns_loss,
  SUM(st.sr_net_loss) AS store_returns_loss,
  SUM(wr.ws_net_profit) AS web_sales_profit,
  SUM(wr.wr_net_loss) AS web_returns_loss,
  SUM(cat.cs_net_profit) - (SUM(cat.cr_net_loss) + SUM(st.sr_net_loss) + SUM(wr.wr_net_loss)) AS net_contribution
FROM catalog cat
CROSS JOIN store st
CROSS JOIN web wr
GROUP BY
  cat.cp_department,
  cat.sm_type,
  cat.catalog_return_reason,
  st.s_store_name,
  wr.web_return_reason
ORDER BY net_contribution DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
