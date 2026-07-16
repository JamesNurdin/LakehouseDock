WITH returns_with_dates AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_order_number,
        cr.cr_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
)
SELECT
    d_ret.d_year,
    d_ret.d_moy AS month,
    sm.sm_type AS ship_mode,
    w.w_warehouse_name AS warehouse,
    COUNT(*) AS total_returns,
    AVG(date_diff('day', d_sold.d_date, d_ret.d_date)) AS avg_days_to_return
FROM returns_with_dates r
JOIN date_dim d_ret
    ON r.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_sold
    ON r.cs_sold_date_sk = d_sold.d_date_sk
JOIN ship_mode sm
    ON r.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON r.cs_warehouse_sk = w.w_warehouse_sk
WHERE d_ret.d_year = 2000
GROUP BY d_ret.d_year, d_ret.d_moy, sm.sm_type, w.w_warehouse_name
ORDER BY d_ret.d_year, d_ret.d_moy, sm.sm_type, w.w_warehouse_name
