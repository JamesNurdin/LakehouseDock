WITH sales_by_income AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_sales_price) AS avg_price,
        COUNT(*) AS txn_cnt
    FROM store_sales ss
    LEFT JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_dep_count >= 2
      AND hd.hd_vehicle_count <= 2
      AND ss.ss_sales_price > 20
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    sbi.ib_income_band_sk,
    sbi.ib_lower_bound,
    sbi.ib_upper_bound,
    sbi.total_sales,
    sbi.avg_price,
    sbi.txn_cnt,
    (
        SELECT MAX(ss2.ss_sales_price)
        FROM store_sales ss2
        JOIN household_demographics hd2
            ON ss2.ss_hdemo_sk = hd2.hd_demo_sk
        WHERE hd2.hd_income_band_sk = sbi.ib_income_band_sk
    ) AS max_price_in_income_band
FROM sales_by_income sbi
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss3
    JOIN household_demographics hd3
        ON ss3.ss_hdemo_sk = hd3.hd_demo_sk
    WHERE hd3.hd_income_band_sk = sbi.ib_income_band_sk
      AND ss3.ss_sales_price > 100
)
ORDER BY sbi.total_sales DESC
LIMIT 100
