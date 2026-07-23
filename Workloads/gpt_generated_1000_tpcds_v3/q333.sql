WITH bill_sales AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(*) AS num_sales,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_net_profit) AS avg_net_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'PROFITABLE' ELSE 'LOSS' END AS profit_status
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_net_paid_inc_ship_tax > 1000
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
ship_sales AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(*) AS num_sales,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_net_profit) AS avg_net_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'PROFITABLE' ELSE 'LOSS' END AS profit_status
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_net_paid_inc_ship_tax > 1000
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    num_sales,
    total_net_profit,
    avg_net_profit,
    profit_status
FROM bill_sales
UNION ALL
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    num_sales,
    total_net_profit,
    avg_net_profit,
    profit_status
FROM ship_sales
ORDER BY ib_income_band_sk, profit_status
LIMIT 100
