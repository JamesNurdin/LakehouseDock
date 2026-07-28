WITH catalog_agg AS (
   SELECT
       cs.cs_item_sk,
       cs.cs_sold_date_sk,
       cs.cs_sold_time_sk,
       cs.cs_ship_mode_sk,
       cs.cs_call_center_sk,
       cs.cs_warehouse_sk,
       cs.cs_order_number,
       SUM(cs.cs_net_paid) AS cs_total_net_paid,
       COUNT(*) AS cs_order_cnt
   FROM catalog_sales cs
   GROUP BY cs.cs_item_sk,
            cs.cs_sold_date_sk,
            cs.cs_sold_time_sk,
            cs.cs_ship_mode_sk,
            cs.cs_call_center_sk,
            cs.cs_warehouse_sk,
            cs.cs_order_number
)
SELECT
    d.d_year,
    i.i_category,
    ib.ib_upper_bound,
    sm.sm_code,
    CASE WHEN ca.cs_total_net_paid > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_level,
    RANK() OVER (PARTITION BY d.d_year ORDER BY ca.cs_total_net_paid DESC) AS sales_rank,
    SUM(ss.ss_net_paid) AS store_total_net_paid,
    SUM(ws.ws_net_paid) AS web_total_net_paid,
    SUM(cr.cr_return_amount) AS catalog_return_total,
    SUM(sr.sr_return_amt) AS store_return_total,
    SUM(wr.wr_return_amt) AS web_return_total,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt
FROM catalog_agg ca
JOIN item i ON ca.cs_item_sk = i.i_item_sk
JOIN date_dim d ON ca.cs_sold_date_sk = d.d_date_sk
JOIN ship_mode sm ON ca.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN call_center cc ON ca.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON ca.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t ON ca.cs_sold_time_sk = t.t_time_sk
JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN reason r_store ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN customer_address ca_addr ON ss.ss_addr_sk = ca_addr.ca_address_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk AND d.d_date_sk = ws.ws_sold_date_sk
JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
JOIN catalog_returns cr ON ca.cs_order_number = cr.cr_order_number
JOIN reason r_catalog ON cr.cr_reason_sk = r_catalog.r_reason_sk
JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
WHERE d.d_year = 2001
  AND ib.ib_upper_bound >= 100000
  AND sm.sm_code = 'AIR'
GROUP BY d.d_year,
         i.i_category,
         ib.ib_upper_bound,
         sm.sm_code,
         CASE WHEN ca.cs_total_net_paid > 10000 THEN 'HIGH' ELSE 'LOW' END,
         ca.cs_total_net_paid
ORDER BY sales_rank
LIMIT 100
