SELECT
    cd.cd_credit_rating,
    hd.hd_buy_potential,
    COUNT(DISTINCT cd.cd_demo_sk) AS num_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
    COUNT(DISTINCT s.s_store_sk) AS num_stores_in_ca,
    COUNT(DISTINCT w.w_warehouse_sk) AS num_warehouses_in_ca
FROM
    customer_demographics cd
JOIN
    household_demographics hd
    ON cd.cd_demo_sk = hd.hd_demo_sk
JOIN
    store s
    ON s.s_state = 'CA'
JOIN
    warehouse w
    ON s.s_state = w.w_state
   AND s.s_city = w.w_city
WHERE
    cd.cd_credit_rating IN ('Excellent', 'Good', 'Fair')
    AND hd.hd_buy_potential = 'High'
    AND cd.cd_gender = 'F'
GROUP BY
    cd.cd_credit_rating,
    hd.hd_buy_potential
ORDER BY
    avg_purchase_estimate DESC
LIMIT 20
