WITH filtered AS (
    SELECT 
        cr.cr_return_amount,
        cr.cr_store_credit,
        cr.cr_return_quantity,
        cc.cc_name,
        cc.cc_company,
        cc.cc_rec_end_date,
        cp.cp_catalog_page_number,
        w.w_city,
        w.w_gmt_offset,
        td.t_hour
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cc.cc_company = 2
      AND cp.cp_catalog_page_number IN (3, 6)
      AND td.t_hour BETWEEN 9 AND 11
      AND w.w_gmt_offset > 0
      AND cc.cc_rec_end_date >= DATE '2000-12-31'
)
SELECT
    f.cc_name,
    f.w_city,
    COUNT(*) AS total_returns,
    SUM(f.cr_return_amount) AS total_return_amount,
    AVG(f.cr_store_credit) AS avg_store_credit,
    MIN(f.cr_return_quantity) AS min_quantity,
    MAX(f.cr_return_quantity) AS max_quantity
FROM filtered f
GROUP BY f.cc_name, f.w_city
ORDER BY total_return_amount DESC
LIMIT 100
