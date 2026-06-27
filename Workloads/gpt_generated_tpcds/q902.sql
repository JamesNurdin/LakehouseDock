WITH ws_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS ws_transactions
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
sr_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        COUNT(*) AS sr_transactions
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
cr_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        COUNT(*) AS cr_transactions
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
)
SELECT
    ws.cd_gender,
    ws.cd_marital_status,
    ws.hd_income_band_sk,
    ws.total_net_paid,
    ws.total_net_profit,
    ws.ws_transactions,
    COALESCE(sr.total_store_net_loss, 0) AS total_store_net_loss,
    COALESCE(sr.sr_transactions, 0) AS store_transactions,
    COALESCE(cr.total_catalog_net_loss, 0) AS total_catalog_net_loss,
    COALESCE(cr.cr_transactions, 0) AS catalog_transactions,
    (ws.total_net_profit - COALESCE(sr.total_store_net_loss, 0) - COALESCE(cr.total_catalog_net_loss, 0)) AS net_contribution
FROM ws_agg ws
LEFT JOIN sr_agg sr
    ON ws.cd_gender = sr.cd_gender
   AND ws.cd_marital_status = sr.cd_marital_status
   AND ws.hd_income_band_sk = sr.hd_income_band_sk
LEFT JOIN cr_agg cr
    ON ws.cd_gender = cr.cd_gender
   AND ws.cd_marital_status = cr.cd_marital_status
   AND ws.hd_income_band_sk = cr.hd_income_band_sk
ORDER BY net_contribution DESC
LIMIT 20
