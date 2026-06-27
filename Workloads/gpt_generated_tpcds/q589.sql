WITH
store_sales_enriched AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        cd.cd_gender,
        hd.hd_income_band_sk,
        c.c_birth_year
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
),
store_returns_enriched AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_net_loss
    FROM store_returns sr
),
catalog_sales_enriched AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_net_profit,
        cs.cs_order_number,
        cd.cd_gender,
        hd.hd_income_band_sk,
        c.c_birth_year
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
),
catalog_returns_enriched AS (
    SELECT
        cr.cr_order_number,
        cr.cr_net_loss
    FROM catalog_returns cr
),
web_sales_enriched AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_net_profit,
        ws.ws_order_number,
        cd.cd_gender,
        hd.hd_income_band_sk,
        c.c_birth_year
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
),
web_returns_enriched AS (
    SELECT
        wr.wr_order_number,
        wr.wr_net_loss
    FROM web_returns wr
)

SELECT
    gender,
    income_band,
    birth_year,
    SUM(profit) AS total_net_profit,
    SUM(loss)   AS total_net_loss,
    SUM(profit) - SUM(loss) AS net_result
FROM (
    SELECT
        ss.cd_gender AS gender,
        ss.hd_income_band_sk AS income_band,
        ss.c_birth_year AS birth_year,
        ss.ss_net_profit AS profit,
        0.0 AS loss
    FROM store_sales_enriched ss

    UNION ALL

    SELECT
        ss.cd_gender AS gender,
        ss.hd_income_band_sk AS income_band,
        ss.c_birth_year AS birth_year,
        0.0 AS profit,
        sr.sr_net_loss AS loss
    FROM store_sales_enriched ss
    JOIN store_returns_enriched sr
        ON ss.ss_ticket_number = sr.sr_ticket_number

    UNION ALL

    SELECT
        cs.cd_gender AS gender,
        cs.hd_income_band_sk AS income_band,
        cs.c_birth_year AS birth_year,
        cs.cs_net_profit AS profit,
        0.0 AS loss
    FROM catalog_sales_enriched cs

    UNION ALL

    SELECT
        cs.cd_gender AS gender,
        cs.hd_income_band_sk AS income_band,
        cs.c_birth_year AS birth_year,
        0.0 AS profit,
        cr.cr_net_loss AS loss
    FROM catalog_sales_enriched cs
    JOIN catalog_returns_enriched cr
        ON cs.cs_order_number = cr.cr_order_number

    UNION ALL

    SELECT
        ws.cd_gender AS gender,
        ws.hd_income_band_sk AS income_band,
        ws.c_birth_year AS birth_year,
        ws.ws_net_profit AS profit,
        0.0 AS loss
    FROM web_sales_enriched ws

    UNION ALL

    SELECT
        ws.cd_gender AS gender,
        ws.hd_income_band_sk AS income_band,
        ws.c_birth_year AS birth_year,
        0.0 AS profit,
        wr.wr_net_loss AS loss
    FROM web_sales_enriched ws
    JOIN web_returns_enriched wr
        ON ws.ws_order_number = wr.wr_order_number
) AS combined
GROUP BY gender, income_band, birth_year
ORDER BY net_result DESC
LIMIT 100
