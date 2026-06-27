WITH
    store_sales_agg AS (
        SELECT
            d.d_year AS year,
            cd.cd_gender AS gender,
            cd.cd_marital_status AS marital_status,
            ss.ss_net_profit AS sales_net_profit
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    ),
    catalog_sales_agg AS (
        SELECT
            d.d_year AS year,
            cd.cd_gender AS gender,
            cd.cd_marital_status AS marital_status,
            cs.cs_net_profit AS sales_net_profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    ),
    web_sales_agg AS (
        SELECT
            d.d_year AS year,
            cd.cd_gender AS gender,
            cd.cd_marital_status AS marital_status,
            ws.ws_net_profit AS sales_net_profit
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    ),
    catalog_returns_agg AS (
        SELECT
            d.d_year AS year,
            cd.cd_gender AS gender,
            cd.cd_marital_status AS marital_status,
            cr.cr_net_loss AS returns_net_loss
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    ),
    web_returns_agg AS (
        SELECT
            d.d_year AS year,
            cd.cd_gender AS gender,
            cd.cd_marital_status AS marital_status,
            wr.wr_net_loss AS returns_net_loss
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    ),
    combined_sales AS (
        SELECT year, gender, marital_status, sales_net_profit, CAST(0 AS decimal(7,2)) AS returns_net_loss FROM store_sales_agg
        UNION ALL
        SELECT year, gender, marital_status, sales_net_profit, CAST(0 AS decimal(7,2)) FROM catalog_sales_agg
        UNION ALL
        SELECT year, gender, marital_status, sales_net_profit, CAST(0 AS decimal(7,2)) FROM web_sales_agg
        UNION ALL
        SELECT year, gender, marital_status, CAST(0 AS decimal(7,2)), returns_net_loss FROM catalog_returns_agg
        UNION ALL
        SELECT year, gender, marital_status, CAST(0 AS decimal(7,2)), returns_net_loss FROM web_returns_agg
    )
SELECT
    year,
    gender,
    marital_status,
    SUM(sales_net_profit) AS total_sales_net_profit,
    SUM(returns_net_loss) AS total_returns_net_loss,
    SUM(sales_net_profit) - SUM(returns_net_loss) AS net_profit_after_returns
FROM combined_sales
GROUP BY year, gender, marital_status
ORDER BY year, gender, marital_status
