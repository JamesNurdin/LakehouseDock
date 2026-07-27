WITH warehouse_loss AS (
    SELECT
        w.w_warehouse_name,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_name
)
SELECT
    order_number,
    return_amount,
    return_tax,
    return_size,
    warehouse_name,
    total_net_loss
FROM (
    SELECT
        cr.cr_order_number AS order_number,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_tax AS return_tax,
        CASE WHEN cr.cr_return_amount > 1000 THEN 'Large' ELSE 'Small' END AS return_size,
        w.w_warehouse_name AS warehouse_name,
        wl.total_net_loss
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse_loss wl ON w.w_warehouse_name = wl.w_warehouse_name
    WHERE ib.ib_lower_bound >= 100000
      AND cr.cr_return_amount IS NOT NULL

    UNION ALL

    SELECT
        cr.cr_order_number AS order_number,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_tax AS return_tax,
        CASE WHEN cr.cr_return_amount > 1000 THEN 'Large' ELSE 'Small' END AS return_size,
        w.w_warehouse_name AS warehouse_name,
        wl.total_net_loss
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse_loss wl ON w.w_warehouse_name = wl.w_warehouse_name
    WHERE hd.hd_vehicle_count = 0
      AND cr.cr_return_amount IS NOT NULL
) AS combined
ORDER BY total_net_loss DESC, order_number
LIMIT 100
