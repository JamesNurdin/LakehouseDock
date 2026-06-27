WITH store_sales_data AS (
    SELECT
        i.i_category,
        cd.cd_gender,
        concat(cast(ib.ib_lower_bound AS varchar), '-', cast(ib.ib_upper_bound AS varchar)) AS income_band_range,
        ss.ss_net_profit AS net_profit,
        ss.ss_net_paid AS net_paid
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
catalog_sales_data AS (
    SELECT
        i.i_category,
        cd.cd_gender,
        concat(cast(ib.ib_lower_bound AS varchar), '-', cast(ib.ib_upper_bound AS varchar)) AS income_band_range,
        cs.cs_net_profit AS net_profit,
        cs.cs_net_paid AS net_paid
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
web_sales_data AS (
    SELECT
        i.i_category,
        cd.cd_gender,
        concat(cast(ib.ib_lower_bound AS varchar), '-', cast(ib.ib_upper_bound AS varchar)) AS income_band_range,
        ws.ws_net_profit AS net_profit,
        ws.ws_net_paid AS net_paid
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    i_category,
    cd_gender,
    income_band_range,
    sum(net_profit) AS total_net_profit,
    sum(net_paid) AS total_net_paid,
    count(*) AS transaction_count
FROM (
    SELECT * FROM store_sales_data
    UNION ALL
    SELECT * FROM catalog_sales_data
    UNION ALL
    SELECT * FROM web_sales_data
) AS all_sales
GROUP BY
    i_category,
    cd_gender,
    income_band_range
ORDER BY total_net_profit DESC
LIMIT 100
