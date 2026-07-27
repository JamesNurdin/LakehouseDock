SELECT
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    COUNT(*) AS returns_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount
FROM
    catalog_returns cr
JOIN
    household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE
    cr.cr_ship_mode_sk = 8
    AND hd.hd_dep_count IN (3, 6)
GROUP BY
    hd.hd_income_band_sk,
    hd.hd_buy_potential
ORDER BY
    total_return_amount DESC
LIMIT 100
