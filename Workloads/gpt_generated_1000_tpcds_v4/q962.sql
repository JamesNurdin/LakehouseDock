WITH base AS (
   SELECT
       cp.cp_department,
       sm.sm_type,
       w.w_gmt_offset,
       cs.cs_order_number,
       cs.cs_net_paid,
       ws.ws_net_paid,
       cr.cr_return_amount,
       sr.sr_return_amt,
       cd_bill.cd_dep_employed_count
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
   JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
   JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
   LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   LEFT JOIN store_returns sr ON sr.sr_cdemo_sk = cd_bill.cd_demo_sk
   LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
   LEFT JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk
   LEFT JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
   LEFT JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
   WHERE cp.cp_department = 'Books'
     AND w.w_gmt_offset = -5.00
     AND sm.sm_type = 'AIR'
     AND web.web_state = 'CA'
),
agg AS (
   SELECT
       cp_department,
       sm_type,
       w_gmt_offset,
       COUNT(DISTINCT cs_order_number) AS order_cnt,
       SUM(cs_net_paid) AS total_cs_sales,
       SUM(ws_net_paid) AS total_ws_sales,
       SUM(cr_return_amount) AS total_cr_returns,
       SUM(sr_return_amt) AS total_sr_returns,
       AVG(cd_dep_employed_count) AS avg_dep_employed
   FROM base
   GROUP BY cp_department, sm_type, w_gmt_offset
   HAVING SUM(cs_net_paid) > 100000
)
SELECT
    cp_department,
    sm_type,
    w_gmt_offset,
    order_cnt,
    total_cs_sales,
    total_ws_sales,
    total_cr_returns,
    total_sr_returns,
    avg_dep_employed,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_cs_sales DESC) AS dept_rank
FROM agg
ORDER BY total_cs_sales DESC
LIMIT 100
