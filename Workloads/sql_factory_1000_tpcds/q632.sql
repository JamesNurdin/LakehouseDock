SELECT sm.sm_ship_mode_id,
       sm.sm_carrier,
       MIN(cs.cs_ext_discount_amt) AS min_discount,
       SUM(cs.cs_quantity) AS total_quantity,
       CASE WHEN AVG(cs.cs_ext_discount_amt) > 1500 THEN 'HIGH_DISCOUNT' ELSE 'LOW_DISCOUNT' END AS discount_category,
       AVG(st.store_avg_net_paid) OVER (PARTITION BY sm.sm_ship_mode_id) AS avg_store_net_paid
FROM catalog_sales cs
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN (
    SELECT ss.ss_hdemo_sk,
           AVG(ss.ss_net_paid) AS store_avg_net_paid
    FROM store_sales ss
    GROUP BY ss.ss_hdemo_sk
) st ON hd.hd_demo_sk = st.ss_hdemo_sk
WHERE hd.hd_income_band_sk BETWEEN 2 AND 6
GROUP BY sm.sm_ship_mode_id, sm.sm_carrier, st.store_avg_net_paid
HAVING SUM(cs.cs_quantity) > 20
ORDER BY min_discount ASC
LIMIT 5
