WITH
    catalog_sales_agg AS (
        SELECT
            cs_bill_cdemo_sk AS cd_demo_sk,
            SUM(cs_net_paid) AS catalog_sales_net_paid,
            SUM(cs_net_profit) AS catalog_sales_net_profit
        FROM catalog_sales
        GROUP BY cs_bill_cdemo_sk
    ),
    web_sales_agg AS (
        SELECT
            ws_bill_cdemo_sk AS cd_demo_sk,
            SUM(ws_net_paid) AS web_sales_net_paid,
            SUM(ws_net_profit) AS web_sales_net_profit
        FROM web_sales
        GROUP BY ws_bill_cdemo_sk
    ),
    store_returns_agg AS (
        SELECT
            sr_cdemo_sk AS cd_demo_sk,
            SUM(sr_return_amt) AS store_returns_amount,
            SUM(sr_net_loss) AS store_returns_net_loss
        FROM store_returns
        GROUP BY sr_cdemo_sk
    ),
    catalog_returns_agg AS (
        SELECT
            cr_refunded_cdemo_sk AS cd_demo_sk,
            SUM(cr_return_amount) AS catalog_returns_amount,
            SUM(cr_net_loss) AS catalog_returns_net_loss
        FROM catalog_returns
        GROUP BY cr_refunded_cdemo_sk
    ),
    web_returns_agg AS (
        SELECT
            wr_refunded_cdemo_sk AS cd_demo_sk,
            SUM(wr_return_amt) AS web_returns_amount,
            SUM(wr_net_loss) AS web_returns_net_loss
        FROM web_returns
        GROUP BY wr_refunded_cdemo_sk
    )
SELECT
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(cs.catalog_sales_net_paid, 0)      AS catalog_sales_net_paid,
    COALESCE(cs.catalog_sales_net_profit, 0)   AS catalog_sales_net_profit,
    COALESCE(ws.web_sales_net_paid, 0)         AS web_sales_net_paid,
    COALESCE(ws.web_sales_net_profit, 0)      AS web_sales_net_profit,
    COALESCE(sr.store_returns_amount, 0)      AS store_returns_amount,
    COALESCE(sr.store_returns_net_loss, 0)    AS store_returns_net_loss,
    COALESCE(cr.catalog_returns_amount, 0)    AS catalog_returns_amount,
    COALESCE(cr.catalog_returns_net_loss, 0)  AS catalog_returns_net_loss,
    COALESCE(wr.web_returns_amount, 0)        AS web_returns_amount,
    COALESCE(wr.web_returns_net_loss, 0)      AS web_returns_net_loss,
    (
        COALESCE(cs.catalog_sales_net_profit, 0) 
        + COALESCE(ws.web_sales_net_profit, 0)
        - COALESCE(sr.store_returns_net_loss, 0)
        - COALESCE(cr.catalog_returns_net_loss, 0)
        - COALESCE(wr.web_returns_net_loss, 0)
    )                                          AS net_profit_after_returns
FROM customer_demographics cd
LEFT JOIN catalog_sales_agg cs   ON cd.cd_demo_sk = cs.cd_demo_sk
LEFT JOIN web_sales_agg ws       ON cd.cd_demo_sk = ws.cd_demo_sk
LEFT JOIN store_returns_agg sr   ON cd.cd_demo_sk = sr.cd_demo_sk
LEFT JOIN catalog_returns_agg cr ON cd.cd_demo_sk = cr.cd_demo_sk
LEFT JOIN web_returns_agg wr     ON cd.cd_demo_sk = wr.cd_demo_sk
ORDER BY net_profit_after_returns DESC
LIMIT 100
