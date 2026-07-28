SELECT
    cc.cc_name,
    cp.cp_department,
    w.w_city,
    w2.w_city AS warehouse_duplicate_city,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN call_center cc2
    ON cr.cr_call_center_sk = cc2.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN warehouse w2
    ON cr.cr_warehouse_sk = w2.w_warehouse_sk
JOIN customer_address ca_refund
    ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_return
    ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
JOIN web_returns wr
    ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_wr_return
    ON wr.wr_returning_addr_sk = ca_wr_return.ca_address_sk
GROUP BY
    cc.cc_name,
    cp.cp_department,
    w.w_city,
    w2.w_city
ORDER BY total_catalog_return_amount DESC
LIMIT 100
