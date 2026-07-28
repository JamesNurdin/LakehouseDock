/* Goal: Compare average net profit and total sales across buy‑potential segments for store sales (male customers) versus web sales (female customers), filtering by income bands and shipping cost, and only keep store rows where a higher income band exists for the same household demographic. */
WITH store_agg AS (
    SELECT
        'store' AS sales_channel,
        hd.hd_buy_potential AS buy_potential,
        AVG(ss.ss_net_profit) AS avg_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cd.cd_gender = 'M'
      AND ib.ib_upper_bound >= 50000
      AND EXISTS (
          SELECT 1
          FROM household_demographics hd2
          JOIN income_band ib2
              ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
          WHERE hd2.hd_demo_sk = hd.hd_demo_sk
            AND ib2.ib_upper_bound > ib.ib_upper_bound
      )
    GROUP BY hd.hd_buy_potential
),
web_agg AS (
    SELECT
        'web' AS sales_channel,
        hd.hd_buy_potential AS buy_potential,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cd.cd_gender = 'F'
      AND ib.ib_lower_bound <= 30000
      AND ws.ws_ext_ship_cost > 1000
    GROUP BY hd.hd_buy_potential
)
SELECT
    sales_channel,
    buy_potential,
    avg_net_profit,
    total_sales
FROM (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
) combined
ORDER BY sales_channel, avg_net_profit DESC
