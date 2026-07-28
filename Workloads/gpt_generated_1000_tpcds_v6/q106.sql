WITH per_cc_wh AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(cr.cr_return_amount) AS sum_return_amount,
        SUM(cr.cr_return_tax) AS sum_return_tax,
        COUNT(*) AS return_cnt
    FROM tpcds.catalog_returns cr
    JOIN tpcds.call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_country = 'United States'
      AND cc.cc_class IN ('large', 'medium')
      AND w.w_state = 'CA'
      AND cr.cr_return_tax > 10
      AND cr.cr_return_amount > 100
      AND cc.cc_employees > 5
      AND w.w_gmt_offset BETWEEN -5.00 AND 0.00
    GROUP BY cc.cc_call_center_id, cc.cc_name, w.w_warehouse_id, w.w_warehouse_name
)
SELECT
    cc_call_center_id,
    cc_name,
    AVG(sum_return_amount) AS avg_return_amount_per_warehouse,
    SUM(return_cnt) AS total_returns,
    MAX(sum_return_tax) AS max_tax_across_warehouses
FROM per_cc_wh
GROUP BY cc_call_center_id, cc_name
HAVING AVG(sum_return_amount) > 5000
ORDER BY avg_return_amount_per_warehouse DESC
LIMIT 100
