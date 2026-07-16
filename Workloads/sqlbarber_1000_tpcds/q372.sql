SELECT
    hd.hd_buy_potential,
    hd.hd_income_band_sk,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(wr.wr_return_amt) AS total_return_amt
FROM
    household_demographics hd
JOIN
    store_sales ss ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN
    web_returns wr ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE
    ss.ss_sold_date_sk = 2451516
    AND wr.wr_returned_date_sk = 2451098
    AND hd.hd_vehicle_count >= 3
GROUP BY
    hd.hd_buy_potential,
    hd.hd_income_band_sk
HAVING
    SUM(ss.ss_net_paid) > 424.96
ORDER BY
    total_net_paid DESC
LIMIT 1000
