WITH store_sales_agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
catalog_sales_agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
web_sales_agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    gender,
    marital_status,
    income_lower,
    income_upper,
    SUM(net_profit) AS total_net_profit,
    COUNT(*) AS transaction_count
FROM (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
) AS combined
GROUP BY gender, marital_status, income_lower, income_upper
ORDER BY total_net_profit DESC
LIMIT 20
