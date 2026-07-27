WITH catalog_agg AS (
    SELECT
        ib.ib_income_band_sk AS income_band_sk,
        ib.ib_upper_bound AS income_upper_bound,
        hd.hd_buy_potential AS buy_potential,
        CAST('Catalog' AS varchar) AS channel,
        AVG(cs.cs_net_profit) AS avg_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_ext_tax > 30
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_upper_bound,
        hd.hd_buy_potential
),
store_agg AS (
    SELECT
        ib.ib_income_band_sk AS income_band_sk,
        ib.ib_upper_bound AS income_upper_bound,
        hd.hd_buy_potential AS buy_potential,
        CAST('Store' AS varchar) AS channel,
        AVG(ss.ss_net_profit) AS avg_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ss.ss_ext_tax > 30
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_upper_bound,
        hd.hd_buy_potential
)
SELECT * FROM catalog_agg
UNION ALL
SELECT * FROM store_agg
ORDER BY income_band_sk, buy_potential, channel
LIMIT 100
