WITH catalog_agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_education_status
),
store_agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        SUM(sr.sr_net_loss) AS total_store_net_loss
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_education_status
),
web_return_agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        SUM(wr.wr_net_loss) AS total_web_return_net_loss
    FROM web_returns wr
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_education_status
),
web_sales_agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        SUM(ws.ws_net_profit) AS total_web_sales_net_profit
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_education_status
)
SELECT
    COALESCE(ca.gender, sa.gender, wra.gender, wsa.gender) AS gender,
    COALESCE(ca.education_status, sa.education_status, wra.education_status, wsa.education_status) AS education_status,
    ca.total_catalog_net_loss,
    sa.total_store_net_loss,
    wra.total_web_return_net_loss,
    wsa.total_web_sales_net_profit,
    COALESCE(ca.total_catalog_net_loss, 0) +
    COALESCE(sa.total_store_net_loss, 0) +
    COALESCE(wra.total_web_return_net_loss, 0) -
    COALESCE(wsa.total_web_sales_net_profit, 0) AS net_impact
FROM catalog_agg ca
FULL OUTER JOIN store_agg sa
    ON ca.gender = sa.gender
   AND ca.education_status = sa.education_status
FULL OUTER JOIN web_return_agg wra
    ON COALESCE(ca.gender, sa.gender) = wra.gender
   AND COALESCE(ca.education_status, sa.education_status) = wra.education_status
FULL OUTER JOIN web_sales_agg wsa
    ON COALESCE(ca.gender, sa.gender, wra.gender) = wsa.gender
   AND COALESCE(ca.education_status, sa.education_status, wra.education_status) = wsa.education_status
ORDER BY gender, education_status
