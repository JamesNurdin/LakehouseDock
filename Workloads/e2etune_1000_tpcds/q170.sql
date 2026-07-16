WITH aggregated AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_item_sk,
        ib.ib_income_band_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        AVG(cr.cr_net_loss) AS avg_net_loss,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN inventory i
      ON cr.cr_item_sk = i.inv_item_sk
     AND cr.cr_warehouse_sk = i.inv_warehouse_sk
     AND cr.cr_returned_date_sk = i.inv_date_sk
    JOIN income_band ib
      ON cr.cr_return_amount BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE cr.cr_return_ship_cost > 100
      AND cr.cr_reason_sk IN (16, 17)
      AND cr.cr_returning_cdemo_sk = 479100
    GROUP BY
        cr.cr_warehouse_sk,
        cr.cr_item_sk,
        ib.ib_income_band_sk
    HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
    a.*, 
    RANK() OVER (ORDER BY a.total_return_amount DESC) AS overall_return_rank
FROM aggregated a
ORDER BY a.total_return_amount DESC
LIMIT 100
