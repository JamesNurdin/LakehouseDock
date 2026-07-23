SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    COUNT(*) AS transaction_count,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_coupon_amt) AS avg_coupon_amount,
    MIN(ss.ss_ext_discount_amt) AS min_discount,
    MAX(ss.ss_ext_discount_amt) AS max_discount
FROM tpcds.store_sales ss
JOIN tpcds.household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    ss.ss_addr_sk IN (3468752, 1766997, 4011076)
    AND ss.ss_coupon_amt > 500.00
    AND ss.ss_ext_sales_price BETWEEN 1000.00 AND 5000.00
    AND hd.hd_buy_potential = '>10000'
    AND hd.hd_vehicle_count >= 2
    AND ib.ib_upper_bound <= 130000
    AND ss.ss_quantity >= 2
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
