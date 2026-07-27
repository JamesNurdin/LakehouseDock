WITH sub1 AS (
   SELECT cc.cc_name AS call_center_name,
          w.w_city AS warehouse_city,
          SUM(cs.cs_net_paid) AS total_net_paid,
          SUM(cs.cs_net_profit) AS total_profit
   FROM tpcds.catalog_sales cs
   JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE cc.cc_mkt_desc LIKE '%Reduced%'
     AND sm.sm_type = 'AIR'
   GROUP BY cc.cc_name, w.w_city
),
sub2 AS (
   SELECT cc.cc_name AS call_center_name,
          w.w_city AS warehouse_city,
          SUM(cs.cs_net_paid) AS total_net_paid,
          SUM(cs.cs_net_profit) AS total_profit
   FROM tpcds.catalog_sales cs
   JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE cp.cp_department = 'DEPARTMENT'
     AND w.w_warehouse_sq_ft > 500000
   GROUP BY cc.cc_name, w.w_city
)
SELECT call_center_name,
       warehouse_city,
       total_net_paid,
       CASE WHEN total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
FROM sub1
UNION ALL
SELECT call_center_name,
       warehouse_city,
       total_net_paid,
       CASE WHEN total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
FROM sub2
ORDER BY total_net_paid DESC, profit_status
LIMIT 100
