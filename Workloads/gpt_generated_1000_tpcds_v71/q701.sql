SELECT
    hd.hd_income_band_sk,
    COUNT(*) AS customer_cnt
FROM
    tpcds.customer c
JOIN
    tpcds.household_demographics hd
      ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE
    c.c_current_addr_sk = 244896
    AND hd.hd_vehicle_count > 0
GROUP BY
    hd.hd_income_band_sk
ORDER BY
    customer_cnt DESC
