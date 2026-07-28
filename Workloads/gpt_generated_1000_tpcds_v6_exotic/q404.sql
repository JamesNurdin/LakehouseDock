WITH bill_stats AS (
    SELECT
        ib.ib_income_band_sk AS ib_income_band_sk,
        ib.ib_lower_bound AS ib_lower_bound,
        ib.ib_upper_bound AS ib_upper_bound,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_ext_list_price > 1000
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    HAVING SUM(cs.cs_net_profit) > 10000
),
ship_stats AS (
    SELECT
        ib.ib_income_band_sk AS ib_income_band_sk,
        ib.ib_lower_bound AS ib_lower_bound,
        ib.ib_upper_bound AS ib_upper_bound,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_ext_list_price > 1000
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    HAVING SUM(cs.cs_net_profit) > 10000
)
SELECT
    'bill' AS source,
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_profit,
    order_cnt
FROM bill_stats
UNION ALL
SELECT
    'ship' AS source,
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_profit,
    order_cnt
FROM ship_stats
ORDER BY total_profit DESC
LIMIT 100
