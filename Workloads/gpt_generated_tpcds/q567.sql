WITH sales_and_returns AS (
    -- Store channel – sales
    SELECT
        d.d_year,
        d.d_moy,
        cd.cd_gender,
        cd.cd_marital_status,
        'Store' AS channel,
        ss.ss_net_profit AS net_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk

    UNION ALL
    -- Store channel – returns (negative impact)
    SELECT
        d.d_year,
        d.d_moy,
        cd.cd_gender,
        cd.cd_marital_status,
        'Store' AS channel,
        -sr.sr_net_loss AS net_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk

    UNION ALL
    -- Catalog channel – sales
    SELECT
        d.d_year,
        d.d_moy,
        cd.cd_gender,
        cd.cd_marital_status,
        'Catalog' AS channel,
        cs.cs_net_profit AS net_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk

    UNION ALL
    -- Catalog channel – returns (negative impact)
    SELECT
        d.d_year,
        d.d_moy,
        cd.cd_gender,
        cd.cd_marital_status,
        'Catalog' AS channel,
        -cr.cr_net_loss AS net_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk

    UNION ALL
    -- Web channel – sales
    SELECT
        d.d_year,
        d.d_moy,
        cd.cd_gender,
        cd.cd_marital_status,
        'Web' AS channel,
        ws.ws_net_profit AS net_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk

    UNION ALL
    -- Web channel – returns (negative impact)
    SELECT
        d.d_year,
        d.d_moy,
        cd.cd_gender,
        cd.cd_marital_status,
        'Web' AS channel,
        -wr.wr_net_loss AS net_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
)
SELECT
    channel,
    d_year,
    d_moy,
    cd_gender,
    cd_marital_status,
    SUM(net_amount) AS net_amount
FROM sales_and_returns
GROUP BY channel, d_year, d_moy, cd_gender, cd_marital_status
ORDER BY channel, d_year, d_moy, cd_gender, cd_marital_status
