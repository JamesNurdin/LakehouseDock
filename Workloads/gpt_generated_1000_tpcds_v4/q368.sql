WITH warehouse_item_returns AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        i.i_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_weekend = 'N'
      AND d.d_holiday = 'N'
      AND w.w_street_type IN ('Road', 'Way')
      AND w.w_gmt_offset = -5.00
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, i.i_category
)
SELECT
    wi.w_warehouse_id,
    wi.w_warehouse_name,
    AVG(wi.total_return_amount) AS avg_return_amount_per_category,
    SUM(wi.total_return_qty) AS total_qty_all_categories,
    COUNT(*) AS category_count
FROM warehouse_item_returns wi
GROUP BY wi.w_warehouse_id, wi.w_warehouse_name
HAVING AVG(wi.total_return_amount) > 1000
ORDER BY avg_return_amount_per_category DESC
LIMIT 100
