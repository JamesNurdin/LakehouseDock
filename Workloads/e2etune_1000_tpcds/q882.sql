WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_quantity_on_hand,
           inv_warehouse_sk,
           inv_date_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 0
)
SELECT
    hd.hd_income_band_sk,
    sm.sm_type,
    ws.web_city,
    SUM(inv_agg.inv_quantity_on_hand) AS total_quantity,
    AVG(inv_agg.inv_quantity_on_hand) AS avg_quantity_per_household,
    COUNT(DISTINCT inv_agg.inv_item_sk) AS distinct_items,
    COUNT(DISTINCT hd.hd_demo_sk) AS households,
    SUM(CASE WHEN hd.hd_buy_potential = '>10000' THEN inv_agg.inv_quantity_on_hand ELSE 0 END) AS high_potential_quantity,
    AVG(ws.web_tax_percentage) AS avg_web_tax_percentage
FROM household_demographics hd
JOIN inv_agg
    ON hd.hd_demo_sk = (inv_agg.inv_item_sk % 5) + 1
JOIN ship_mode sm
    ON (inv_agg.inv_warehouse_sk % 3) = (sm.sm_ship_mode_sk % 3)
JOIN web_site ws
    ON (ws.web_site_sk % 2) = (hd.hd_income_band_sk % 2)
WHERE hd.hd_vehicle_count >= 2
  AND hd.hd_dep_count <= 2
  AND sm.sm_type IN ('AIR', 'GROUND')
  AND ws.web_state = 'CA'
GROUP BY hd.hd_income_band_sk, sm.sm_type, ws.web_city
HAVING SUM(inv_agg.inv_quantity_on_hand) > 1000
ORDER BY total_quantity DESC
LIMIT 50
