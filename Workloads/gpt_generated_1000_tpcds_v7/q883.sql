SELECT
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_quantity) AS avg_quantity,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    MIN(ss.ss_sales_price) AS min_sales_price,
    MAX(ss.ss_sales_price) AS max_sales_price
FROM
    tpcds.store_sales ss
JOIN
    tpcds.customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN
    tpcds.household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN
    tpcds.income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    cd.cd_gender = 'M'
    AND cd.cd_marital_status = 'M'
    AND cd.cd_education_status = 'College'
    AND cd.cd_dep_college_count >= 1
    AND hd.hd_buy_potential = '5001-10000'
    AND ib.ib_upper_bound <= 120000
    AND ss.ss_quantity > 1
    AND ss.ss_sales_price > 10
GROUP BY
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound
ORDER BY
    total_net_paid DESC
LIMIT 100
