SELECT
    ca.ca_state,
    ca.ca_city,
    COUNT(DISTINCT cd.cd_demo_sk) AS num_customers,
    SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
    AVG(hd.hd_income_band_sk) AS avg_income_band,
    COUNT(DISTINCT sm.sm_ship_mode_id) AS distinct_ship_modes
FROM
    customer_address ca
    JOIN customer_demographics cd ON true
    JOIN household_demographics hd ON true
    JOIN ship_mode sm ON true
WHERE
    ca.ca_state IN ('AZ', 'NM', 'PA')
    AND cd.cd_gender = 'M'
    AND cd.cd_credit_rating = 'Good'
    AND hd.hd_buy_potential = 'High'
    AND sm.sm_type = 'AIR'
GROUP BY
    ca.ca_state,
    ca.ca_city
HAVING
    COUNT(*) > 10
ORDER BY
    total_purchase_estimate DESC
LIMIT 50
