WITH filtered_sales AS (
    SELECT
        ss.ss_hdemo_sk,
        ss.ss_net_paid,
        ss.ss_ext_discount_amt,
        ss.ss_coupon_amt,
        ss.ss_quantity,
        ss.ss_sold_time_sk
    FROM store_sales ss
    WHERE ss.ss_coupon_amt > 1000
      AND ss.ss_sold_time_sk IN (34466, 62630, 61768)
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(*) AS sales_cnt,
    SUM(fs.ss_net_paid) AS total_net_paid,
    AVG(fs.ss_ext_discount_amt) AS avg_discount,
    SUM(CASE WHEN fs.ss_coupon_amt > 5000 THEN 1 ELSE 0 END) AS high_coupon_cnt,
    MAX(fs.ss_quantity) AS max_quantity,
    (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2) AS overall_avg_net_paid
FROM filtered_sales fs
JOIN household_demographics hd
    ON fs.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_vehicle_count >= 1
  AND ib.ib_upper_bound <= 100000
  AND hd.hd_dep_count BETWEEN 4 AND 7
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
HAVING SUM(fs.ss_net_paid) > 50000
ORDER BY total_net_paid DESC
LIMIT 100
