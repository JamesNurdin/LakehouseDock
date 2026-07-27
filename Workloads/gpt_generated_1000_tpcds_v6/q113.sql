SELECT
    cc.cc_market_manager,
    cp.cp_department,
    w.w_state,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    MIN(cr.cr_return_tax) AS min_return_tax,
    MAX(cr.cr_fee) AS max_fee
FROM tpcds.catalog_returns cr
JOIN tpcds.call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE
  cc.cc_country = 'United States'
  AND cc.cc_mkt_id = 3
  AND cp.cp_catalog_page_id = 'AAAAAAAACAAAAAAA'
  AND w.w_gmt_offset = -5.00
  AND cr.cr_return_amount > 10
GROUP BY GROUPING SETS (
    (cc.cc_market_manager, cp.cp_department, w.w_state),
    (cc.cc_market_manager, cp.cp_department),
    (cc.cc_market_manager),
    ()
)
ORDER BY
  SUM(cr.cr_return_amount) DESC,
  cc.cc_market_manager,
  cp.cp_department,
  w.w_state
LIMIT 100
