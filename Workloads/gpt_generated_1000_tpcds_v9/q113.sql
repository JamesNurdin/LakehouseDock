WITH income_category AS (
    SELECT
        ib_income_band_sk,
        CASE
            WHEN ib_lower_bound >= 100000 THEN 'HighIncome'
            WHEN ib_upper_bound <= 50000 THEN 'LowIncome'
            ELSE 'MidIncome'
        END AS income_cat
    FROM income_band
)
SELECT
    segment,
    store_id,
    total_sales,
    total_profit,
    sales_cnt
FROM (
    SELECT
        ic.income_cat AS segment,
        ss.ss_store_sk AS store_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_category ic
        ON hd.hd_income_band_sk = ic.ib_income_band_sk
    WHERE ic.income_cat = 'HighIncome'
      AND hd.hd_vehicle_count >= 2
    GROUP BY ic.income_cat, ss.ss_store_sk
    UNION ALL
    SELECT
        ic.income_cat AS segment,
        ss.ss_store_sk AS store_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_category ic
        ON hd.hd_income_band_sk = ic.ib_income_band_sk
    WHERE ic.income_cat = 'LowIncome'
      AND hd.hd_dep_count <= 1
    GROUP BY ic.income_cat, ss.ss_store_sk
) t
ORDER BY segment, total_sales DESC
LIMIT 100
