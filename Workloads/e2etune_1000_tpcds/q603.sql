SELECT
    cp.cp_department,
    sm.sm_carrier,
    hd.hd_buy_potential,
    ca.ca_state,
    COUNT(DISTINCT i.i_item_id) AS distinct_item_cnt,
    AVG(i.i_current_price) AS avg_current_price,
    SUM(i.i_current_price * COALESCE(hd.hd_vehicle_count, 1)) AS weighted_price,
    SUM(i.i_wholesale_cost) AS total_wholesale_cost,
    RANK() OVER (ORDER BY SUM(i.i_current_price * COALESCE(hd.hd_vehicle_count, 1)) DESC) AS price_rank
FROM catalog_page cp
JOIN item i
    ON cp.cp_catalog_page_sk = i.i_item_sk
JOIN ship_mode sm
    ON cp.cp_end_date_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd
    ON i.i_brand_id = hd.hd_income_band_sk
JOIN customer_address ca
    ON cp.cp_start_date_sk = ca.ca_address_sk
WHERE cp.cp_type = 'monthly'
  AND i.i_rec_start_date >= DATE '2023-01-01'
  AND hd.hd_buy_potential = 'HIGH'
GROUP BY
    cp.cp_department,
    sm.sm_carrier,
    hd.hd_buy_potential,
    ca.ca_state
HAVING COUNT(DISTINCT i.i_item_id) >= 5
ORDER BY weighted_price DESC
LIMIT 50
