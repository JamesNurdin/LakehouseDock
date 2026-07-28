SELECT
    cc.cc_name,
    w.w_state,
    cp.cp_type,
    r.r_reason_desc,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    AVG(ws.ws_ext_ship_cost) AS avg_ship_cost
FROM tpcds.catalog_sales cs
JOIN tpcds.customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
JOIN tpcds.reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN tpcds.web_sales ws
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
WHERE cc.cc_state = 'CA'
  AND w.w_city = 'Seattle'
  AND cp.cp_catalog_number = 5
  AND we.web_rec_start_date >= DATE '2000-01-01'
  AND we.web_rec_start_date < DATE '2001-01-01'
GROUP BY cc.cc_name, w.w_state, cp.cp_type, r.r_reason_desc
LIMIT 100
