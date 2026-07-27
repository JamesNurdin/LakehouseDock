WITH agg AS (
    SELECT
        cc.cc_state AS cc_state,
        cp.cp_department AS department,
        w.w_state AS warehouse_state,
        COUNT(DISTINCT cr.cr_order_number) AS orders_count,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        MIN(cr.cr_return_amount) AS min_return_amount,
        MAX(cr.cr_return_amount) AS max_return_amount
    FROM tpcds.catalog_returns cr
    JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE
        cc.cc_state = 'CA'
        AND cc.cc_gmt_offset BETWEEN -8.00 AND -5.00
        AND cc.cc_employees > 50
        AND cp.cp_department IN ('Electronics', 'Furniture')
        AND cp.cp_catalog_number BETWEEN 10 AND 100
        AND cr.cr_return_quantity >= 5
        AND cr.cr_return_amount > 10.00
        AND w.w_state = 'CA'
        AND EXISTS (
            SELECT 1
            FROM tpcds.catalog_page cp2
            WHERE cp2.cp_catalog_page_sk = cr.cr_catalog_page_sk
              AND cp2.cp_type = 'WEB'
        )
    GROUP BY
        cc.cc_state,
        cp.cp_department,
        w.w_state
)
SELECT
    agg.cc_state,
    agg.department,
    agg.warehouse_state,
    agg.orders_count,
    agg.total_return_amount,
    agg.avg_return_qty,
    agg.min_return_amount,
    agg.max_return_amount,
    SUM(agg.total_return_amount) OVER (
        PARTITION BY agg.cc_state
        ORDER BY agg.total_return_amount DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_by_state
FROM agg
ORDER BY agg.total_return_amount DESC
LIMIT 100
