WITH cr_agg AS (
    SELECT
        cr_warehouse_sk,
        cr_returned_date_sk,
        cr_call_center_sk,
        cr_catalog_page_sk,
        cr_refunded_addr_sk,
        cr_returning_addr_sk,
        SUM(cr_return_amount) AS sum_return_amount,
        SUM(cr_return_quantity) AS sum_return_quantity,
        COUNT(*) AS cnt_returns,
        SUM(CASE WHEN cr_return_tax > 0 THEN cr_return_tax ELSE 0 END) AS sum_return_tax,
        AVG(cr_return_amount) AS avg_return_amount
    FROM catalog_returns
    WHERE cr_return_amount > 100
      AND cr_return_quantity >= 1
      AND cr_return_tax IS NOT NULL
    GROUP BY
        cr_warehouse_sk,
        cr_returned_date_sk,
        cr_call_center_sk,
        cr_catalog_page_sk,
        cr_refunded_addr_sk,
        cr_returning_addr_sk
)
SELECT
    w.w_warehouse_name,
    cc.cc_name,
    cp.cp_department,
    dr.d_year,
    dr.d_month_seq,
    SUM(cr_agg.sum_return_amount) AS total_return_amount,
    SUM(cr_agg.sum_return_quantity) AS total_return_quantity,
    AVG(cr_agg.avg_return_amount) AS avg_return_amount,
    CASE WHEN SUM(cr_agg.sum_return_amount) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
FROM cr_agg
JOIN warehouse w ON w.w_warehouse_sk = cr_agg.cr_warehouse_sk
JOIN date_dim dr ON dr.d_date_sk = cr_agg.cr_returned_date_sk
JOIN call_center cc ON cc.cc_call_center_sk = cr_agg.cr_call_center_sk
JOIN catalog_page cp ON cp.cp_catalog_page_sk = cr_agg.cr_catalog_page_sk
JOIN customer_address ca_ref ON ca_ref.ca_address_sk = cr_agg.cr_refunded_addr_sk
JOIN customer_address ca_ret ON ca_ret.ca_address_sk = cr_agg.cr_returning_addr_sk
WHERE dr.d_year = 2001
  AND w.w_state = 'CA'
  AND cc.cc_state = 'CA'
  AND cp.cp_department = 'Electronics'
  AND ca_ret.ca_city = 'Seattle'
GROUP BY
    w.w_warehouse_name,
    cc.cc_name,
    cp.cp_department,
    dr.d_year,
    dr.d_month_seq
HAVING
    COUNT(*) > 10
    AND SUM(cr_agg.sum_return_amount) > 5000
ORDER BY
    total_return_amount DESC
LIMIT 100
