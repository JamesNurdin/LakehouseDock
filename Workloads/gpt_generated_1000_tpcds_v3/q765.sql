WITH catalog_agg AS (
    SELECT
        ib.ib_income_band_sk AS income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        i.i_category AS category,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_ship_date_sk BETWEEN 2450830 AND 2450914
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, i.i_category
),
web_agg AS (
    SELECT
        ib.ib_income_band_sk AS income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        i.i_category AS category,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_ship_date_sk BETWEEN 2451545 AND 2452277
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, i.i_category
)
SELECT
    income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    category,
    SUM(total_profit) AS combined_profit
FROM (
    SELECT income_band_sk, ib_lower_bound, ib_upper_bound, category, total_profit
    FROM catalog_agg
    UNION ALL
    SELECT income_band_sk, ib_lower_bound, ib_upper_bound, category, total_profit
    FROM web_agg
) u
GROUP BY income_band_sk, ib_lower_bound, ib_upper_bound, category
ORDER BY combined_profit DESC
LIMIT 100
