WITH per_store AS (
    SELECT
        cc.cc_call_center_id,
        cp.cp_department,
        ca.ca_state,
        td.t_hour,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        COUNT(*) AS return_cnt
    FROM tpcds.catalog_returns cr
    JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN tpcds.customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cc.cc_state = 'CA'
      AND cp.cp_type = 'monthly'
      AND ca.ca_gmt_offset BETWEEN -5.00 AND 5.00
      AND cr.cr_return_amount > 100.00
      AND td.t_hour BETWEEN 9 AND 17
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY
        cc.cc_call_center_id,
        cp.cp_department,
        ca.ca_state,
        td.t_hour
)
SELECT
    cc_call_center_id,
    cp_department,
    ca_state,
    AVG(total_return_amount) AS avg_total_return_amount,
    SUM(total_return_qty) AS sum_total_return_qty,
    COUNT(*) AS num_hours
FROM per_store
WHERE total_return_amount > 500.00
GROUP BY
    cc_call_center_id,
    cp_department,
    ca_state
ORDER BY avg_total_return_amount DESC
