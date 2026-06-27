WITH sales_by_income_buy AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        COUNT(*) AS sales_count,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ss.ss_hdemo_sk) AS distinct_households,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        AVG(hd.hd_dep_count) AS avg_dep_count
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    sales_count,
    total_net_paid,
    total_net_profit,
    avg_net_profit,
    distinct_households,
    total_quantity,
    avg_vehicle_count,
    avg_dep_count
FROM sales_by_income_buy
ORDER BY total_net_profit DESC
LIMIT 20
