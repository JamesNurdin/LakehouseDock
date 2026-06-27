WITH
    store_sales_demo AS (
        SELECT
            cd.cd_gender,
            cd.cd_marital_status,
            ss.ss_net_profit AS net_profit,
            1 AS sales_count,
            0 AS returns_count,
            CAST(0 AS decimal(7,2)) AS net_loss
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    ),
    catalog_sales_demo AS (
        SELECT
            cd.cd_gender,
            cd.cd_marital_status,
            cs.cs_net_profit AS net_profit,
            1 AS sales_count,
            0 AS returns_count,
            CAST(0 AS decimal(7,2)) AS net_loss
        FROM catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    ),
    web_sales_demo AS (
        SELECT
            cd.cd_gender,
            cd.cd_marital_status,
            ws.ws_net_profit AS net_profit,
            1 AS sales_count,
            0 AS returns_count,
            CAST(0 AS decimal(7,2)) AS net_loss
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    ),
    store_returns_demo AS (
        SELECT
            cd.cd_gender,
            cd.cd_marital_status,
            CAST(0 AS decimal(7,2)) AS net_profit,
            0 AS sales_count,
            1 AS returns_count,
            sr.sr_net_loss AS net_loss
        FROM store_returns sr
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    ),
    catalog_returns_demo AS (
        SELECT
            cd.cd_gender,
            cd.cd_marital_status,
            CAST(0 AS decimal(7,2)) AS net_profit,
            0 AS sales_count,
            1 AS returns_count,
            cr.cr_net_loss AS net_loss
        FROM catalog_returns cr
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    ),
    web_returns_demo AS (
        SELECT
            cd.cd_gender,
            cd.cd_marital_status,
            CAST(0 AS decimal(7,2)) AS net_profit,
            0 AS sales_count,
            1 AS returns_count,
            wr.wr_net_loss AS net_loss
        FROM web_returns wr
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    ),
    combined AS (
        SELECT * FROM store_sales_demo
        UNION ALL
        SELECT * FROM catalog_sales_demo
        UNION ALL
        SELECT * FROM web_sales_demo
        UNION ALL
        SELECT * FROM store_returns_demo
        UNION ALL
        SELECT * FROM catalog_returns_demo
        UNION ALL
        SELECT * FROM web_returns_demo
    )
SELECT
    cd_gender,
    cd_marital_status,
    SUM(net_profit) AS total_net_profit,
    SUM(net_loss) AS total_net_loss,
    SUM(sales_count) AS total_sales_transactions,
    SUM(returns_count) AS total_return_transactions,
    CASE WHEN SUM(sales_count) > 0 THEN SUM(net_profit) / SUM(sales_count) ELSE NULL END AS avg_profit_per_sale,
    CASE WHEN SUM(returns_count) > 0 THEN SUM(net_loss) / SUM(returns_count) ELSE NULL END AS avg_loss_per_return,
    CASE WHEN (SUM(sales_count) + SUM(returns_count)) > 0 THEN SUM(returns_count) / (SUM(sales_count) + SUM(returns_count)) ELSE NULL END AS return_rate
FROM combined
GROUP BY cd_gender, cd_marital_status
ORDER BY total_net_profit DESC
LIMIT 20
