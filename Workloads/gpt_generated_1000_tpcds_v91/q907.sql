WITH union_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_hdemo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ss.ss_net_profit,
        ss.ss_quantity
    FROM tpcds.store_sales ss
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ss.ss_quantity > 5
        AND hd.hd_vehicle_count >= 0
        AND ib.ib_lower_bound >= 100001
    UNION ALL
    SELECT
        ss.ss_store_sk,
        ss.ss_hdemo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ss.ss_net_profit,
        ss.ss_quantity
    FROM tpcds.store_sales ss
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ss.ss_quantity <= 5
        AND hd.hd_dep_count BETWEEN 2 AND 7
        AND ib.ib_lower_bound < 150000
)
SELECT
    us.ss_store_sk,
    us.ss_hdemo_sk,
    us.hd_income_band_sk,
    us.hd_buy_potential,
    us.ib_lower_bound,
    us.ss_net_profit,
    us.ss_quantity,
    (
        SELECT AVG(ss2.ss_net_profit)
        FROM tpcds.store_sales ss2
        JOIN tpcds.household_demographics hd2 ON ss2.ss_hdemo_sk = hd2.hd_demo_sk
        JOIN tpcds.income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
        WHERE ib2.ib_income_band_sk = us.hd_income_band_sk
    ) AS avg_profit_by_band,
    CASE
        WHEN us.ss_net_profit > (
            SELECT AVG(ss2.ss_net_profit)
            FROM tpcds.store_sales ss2
            JOIN tpcds.household_demographics hd2 ON ss2.ss_hdemo_sk = hd2.hd_demo_sk
            JOIN tpcds.income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
            WHERE ib2.ib_income_band_sk = us.hd_income_band_sk
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY us.hd_income_band_sk ORDER BY us.ss_net_profit DESC) AS rn_by_income_band,
    ROW_NUMBER() OVER (ORDER BY us.ss_net_profit DESC) AS global_rn
FROM union_sales us
WHERE
    us.ss_net_profit > 0
    AND us.hd_buy_potential IS NOT NULL
    AND us.ib_lower_bound <= 200000
ORDER BY global_rn
LIMIT 100
