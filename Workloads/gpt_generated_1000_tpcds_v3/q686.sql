SELECT
    cc.cc_division_name,
    w.w_state,
    r.r_reason_desc,
    cd.cd_gender,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(*) AS return_cnt,
    MIN(cr.cr_return_quantity) AS min_return_qty,
    MAX(cr.cr_return_quantity) AS max_return_qty,
    CASE WHEN SUM(cr.cr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
FROM tpcds.catalog_returns cr
JOIN tpcds.catalog_sales cs
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_item_sk = cs.cs_item_sk
JOIN tpcds.call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
  AND cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
  AND cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN tpcds.customer_demographics cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE cs.cs_ext_list_price > 5000
  AND cs.cs_quantity BETWEEN 2 AND 5
  AND cc.cc_division_name = 'anti'
  AND w.w_state = 'CA'
  AND cd.cd_gender = 'M'
  AND r.r_reason_id = 'AAAAAAAABBAAAAAA'
GROUP BY cc.cc_division_name, w.w_state, r.r_reason_desc, cd.cd_gender
HAVING SUM(cr.cr_net_loss) > 5000
ORDER BY total_net_loss DESC
LIMIT 100
