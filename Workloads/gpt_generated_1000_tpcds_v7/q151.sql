SELECT
    hd.hd_buy_potential,
    COUNT(*) AS customer_cnt
FROM
    tpcds.customer c
JOIN
    tpcds.household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE
    c.c_birth_month = 3
    AND hd.hd_dep_count >= 4
GROUP BY
    hd.hd_buy_potential
ORDER BY
    customer_cnt DESC
