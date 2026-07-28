WITH returns_summary AS (
    SELECT
        d.d_year AS return_year,
        w.w_warehouse_id,
        sm.sm_type AS ship_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        CASE WHEN AVG(cr.cr_return_tax) > 50 THEN 'HighTax' ELSE 'LowTax' END AS tax_category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2000
      AND EXISTS (
            SELECT 1
            FROM inventory i
            WHERE i.inv_date_sk = d.d_date_sk
              AND i.inv_warehouse_sk = w.w_warehouse_sk
              AND i.inv_quantity_on_hand > 0
        )
    GROUP BY d.d_year, w.w_warehouse_id, sm.sm_type

    UNION ALL

    SELECT
        d.d_year AS return_year,
        w.w_warehouse_id,
        sm.sm_type AS ship_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        CASE WHEN AVG(cr.cr_return_tax) > 50 THEN 'HighTax' ELSE 'LowTax' END AS tax_category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND EXISTS (
            SELECT 1
            FROM inventory i
            WHERE i.inv_date_sk = d.d_date_sk
              AND i.inv_warehouse_sk = w.w_warehouse_sk
              AND i.inv_quantity_on_hand > 0
        )
    GROUP BY d.d_year, w.w_warehouse_id, sm.sm_type
)
SELECT
    rs.return_year,
    rs.w_warehouse_id,
    rs.ship_type,
    rs.total_return_amount,
    rs.total_net_loss,
    rs.loss_category,
    rs.distinct_orders,
    rs.tax_category,
    (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2) AS overall_avg_return_amount
FROM returns_summary rs
ORDER BY rs.return_year ASC,
         rs.loss_category DESC,
         rs.total_net_loss DESC
