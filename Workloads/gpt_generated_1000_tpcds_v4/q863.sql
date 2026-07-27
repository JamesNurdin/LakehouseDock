WITH
joined_data AS (
   SELECT
       cc.cc_name,
       cp.cp_department,
       sm.sm_carrier,
       i1.i_item_id,
       r.r_reason_desc,
       r2.r_reason_desc AS web_return_reason,
       wp.wp_type,
       cs.cs_net_profit,
       ss.ss_net_profit,
       cr.cr_return_amount,
       wr.wr_return_amt,
       cs.cs_order_number
   FROM catalog_sales cs
   JOIN call_center cc
       ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp
       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm
       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN item i1
       ON cs.cs_item_sk = i1.i_item_sk
   JOIN catalog_returns cr
       ON cr.cr_order_number = cs.cs_order_number
      AND cr.cr_item_sk = cs.cs_item_sk
   JOIN call_center cc_ret
       ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
   JOIN catalog_page cp_ret
       ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
   JOIN ship_mode sm_ret
       ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
   JOIN reason r
       ON cr.cr_reason_sk = r.r_reason_sk
   JOIN store_sales ss
       ON ss.ss_item_sk = i1.i_item_sk
   JOIN web_returns wr
       ON wr.wr_item_sk = i1.i_item_sk
   JOIN web_page wp
       ON wr.wr_web_page_sk = wp.wp_web_page_sk
   JOIN reason r2
       ON wr.wr_reason_sk = r2.r_reason_sk
   WHERE cp.cp_catalog_number = 7
     AND sm.sm_carrier = 'UPS'
)
SELECT
    cc_name,
    cp_department,
    sm_carrier,
    i_item_id,
    r_reason_desc,
    web_return_reason,
    wp_type,
    SUM(cs_net_profit) AS total_catalog_sales_profit,
    SUM(ss_net_profit) AS total_store_sales_profit,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(wr_return_amt) AS total_web_return_amount,
    COUNT(DISTINCT cs_order_number) AS distinct_orders
FROM joined_data
GROUP BY
    cc_name,
    cp_department,
    sm_carrier,
    i_item_id,
    r_reason_desc,
    web_return_reason,
    wp_type
ORDER BY total_catalog_sales_profit DESC, total_store_sales_profit DESC
LIMIT 100
