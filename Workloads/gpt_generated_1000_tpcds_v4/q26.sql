WITH recent_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
)
SELECT DISTINCT
    src.source_type,
    src.location_name,
    src.total_return_amount,
    src.order_count
FROM (
    SELECT
        'Warehouse' AS source_type,
        w.w_warehouse_name AS location_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS order_count
    FROM catalog_returns cr
    JOIN recent_dates rd ON cr.cr_returned_date_sk = rd.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_name
    HAVING SUM(cr.cr_return_amount) > 10000

    UNION ALL

    SELECT
        'CallCenter' AS source_type,
        cc.cc_name AS location_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS order_count
    FROM catalog_returns cr
    JOIN recent_dates rd ON cr.cr_returned_date_sk = rd.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    GROUP BY cc.cc_name
    HAVING SUM(cr.cr_return_amount) > 10000
) AS src
ORDER BY src.total_return_amount DESC
LIMIT 100
