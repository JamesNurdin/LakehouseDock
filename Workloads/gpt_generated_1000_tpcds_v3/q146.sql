WITH filtered_returns AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_reversed_charge,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk
    FROM catalog_returns cr
    WHERE cr.cr_net_loss > 500
      AND cr.cr_reversed_charge < 200
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    sm.sm_code,
    CASE WHEN sm.sm_code = 'AIR' THEN 'Fast' ELSE 'Standard' END AS shipping_speed_category,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_net_loss) AS avg_net_loss,
    SUM(fr.cr_return_quantity) AS total_return_quantity,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT fr.cr_item_sk) AS distinct_items_returned,
    SUM(CASE WHEN fr.cr_return_amount > 100 THEN fr.cr_return_amount ELSE 0 END) AS high_return_amount_sum,
    MAX(fr.cr_return_amount) AS max_return_amount
FROM filtered_returns fr
JOIN ship_mode sm
    ON fr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON fr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_country = 'United States'
  AND w.w_street_type IN ('Ave', 'Rd', 'Street')
  AND sm.sm_code = 'AIR'
  AND i.inv_quantity_on_hand > 0
GROUP BY
    w.w_warehouse_id,
    w.w_city,
    sm.sm_code,
    CASE WHEN sm.sm_code = 'AIR' THEN 'Fast' ELSE 'Standard' END
HAVING
    SUM(fr.cr_return_amount) > 1000
    AND COUNT(DISTINCT fr.cr_item_sk) >= 5
ORDER BY total_return_amount DESC
LIMIT 100
