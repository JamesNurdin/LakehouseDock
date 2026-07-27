SELECT
    hd.hd_buy_potential,
    SUM(cs.cs_ext_sales_price) AS total_sales
FROM
    catalog_sales cs
JOIN
    household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE
    cs.cs_wholesale_cost > 50.00
    AND hd.hd_income_band_sk = 11
GROUP BY
    hd.hd_buy_potential
ORDER BY
    total_sales DESC
LIMIT 100
