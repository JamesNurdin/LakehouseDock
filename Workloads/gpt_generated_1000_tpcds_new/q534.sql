WITH hd_ib_full AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM household_demographics hd
    FULL OUTER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    hd.hd_buy_potential,
    hd.ib_lower_bound,
    ss.ss_store_sk,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_ext_tax) AS avg_tax,
    COUNT(*) AS transaction_cnt,
    MIN(ss.ss_net_paid) AS min_net_paid,
    MAX(ss.ss_net_paid) AS max_net_paid,
    SUM(l.ten_percent) AS ten_percent_sum
FROM store_sales ss
LEFT JOIN hd_ib_full hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
CROSS JOIN LATERAL (
    SELECT ss.ss_ext_sales_price * 0.1 AS ten_percent
) AS l
WHERE
    ss.ss_quantity > 0
    AND ss.ss_ext_tax > 10.00
    AND hd.hd_vehicle_count >= 0
    AND hd.ib_lower_bound = (
        SELECT MIN(ib_lower_bound)
        FROM income_band
        WHERE ib_income_band_sk = 5
    )
    AND ss.ss_store_sk IN (
        SELECT DISTINCT ss_store_sk
        FROM store_sales
        WHERE ss_net_profit > 0
    )
GROUP BY CUBE (hd.hd_buy_potential, hd.ib_lower_bound, ss.ss_store_sk)
HAVING SUM(ss.ss_ext_sales_price) > 0
ORDER BY total_sales DESC
OFFSET 0 LIMIT 100
