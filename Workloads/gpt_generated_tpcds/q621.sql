WITH
    store_sales_agg AS (
        SELECT
            d_s.d_year AS year,
            cd.cd_gender AS gender,
            SUM(ss.ss_net_profit) AS sales_profit
        FROM store_sales ss
        JOIN date_dim d_s
            ON ss.ss_sold_date_sk = d_s.d_date_sk
        JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        GROUP BY d_s.d_year, cd.cd_gender
    ),
    store_returns_agg AS (
        SELECT
            d_r.d_year AS year,
            cd.cd_gender AS gender,
            SUM(sr.sr_net_loss) AS returns_loss
        FROM store_returns sr
        JOIN date_dim d_r
            ON sr.sr_returned_date_sk = d_r.d_date_sk
        JOIN customer_demographics cd
            ON sr.sr_cdemo_sk = cd.cd_demo_sk
        GROUP BY d_r.d_year, cd.cd_gender
    ),
    catalog_sales_agg AS (
        SELECT
            d_s.d_year AS year,
            cd.cd_gender AS gender,
            SUM(cs.cs_net_profit) AS sales_profit
        FROM catalog_sales cs
        JOIN date_dim d_s
            ON cs.cs_sold_date_sk = d_s.d_date_sk
        JOIN customer_demographics cd
            ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        GROUP BY d_s.d_year, cd.cd_gender
    ),
    catalog_returns_agg AS (
        SELECT
            d_r.d_year AS year,
            cd.cd_gender AS gender,
            SUM(cr.cr_net_loss) AS returns_loss
        FROM catalog_returns cr
        JOIN date_dim d_r
            ON cr.cr_returned_date_sk = d_r.d_date_sk
        JOIN customer_demographics cd
            ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        GROUP BY d_r.d_year, cd.cd_gender
    ),
    web_sales_agg AS (
        SELECT
            d_s.d_year AS year,
            cd.cd_gender AS gender,
            SUM(ws.ws_net_profit) AS sales_profit
        FROM web_sales ws
        JOIN date_dim d_s
            ON ws.ws_sold_date_sk = d_s.d_date_sk
        JOIN customer_demographics cd
            ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        GROUP BY d_s.d_year, cd.cd_gender
    ),
    web_returns_agg AS (
        SELECT
            d_r.d_year AS year,
            cd.cd_gender AS gender,
            SUM(wr.wr_net_loss) AS returns_loss
        FROM web_returns wr
        JOIN date_dim d_r
            ON wr.wr_returned_date_sk = d_r.d_date_sk
        JOIN customer_demographics cd
            ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        GROUP BY d_r.d_year, cd.cd_gender
    ),
    store_combined AS (
        SELECT
            ss.year,
            ss.gender,
            ss.sales_profit,
            COALESCE(sr.returns_loss, 0) AS returns_loss,
            ss.sales_profit - COALESCE(sr.returns_loss, 0) AS net_profit_after_returns
        FROM store_sales_agg ss
        LEFT JOIN store_returns_agg sr
            ON ss.year = sr.year AND ss.gender = sr.gender
    ),
    catalog_combined AS (
        SELECT
            cs.year,
            cs.gender,
            cs.sales_profit,
            COALESCE(cr.returns_loss, 0) AS returns_loss,
            cs.sales_profit - COALESCE(cr.returns_loss, 0) AS net_profit_after_returns
        FROM catalog_sales_agg cs
        LEFT JOIN catalog_returns_agg cr
            ON cs.year = cr.year AND cs.gender = cr.gender
    ),
    web_combined AS (
        SELECT
            ws.year,
            ws.gender,
            ws.sales_profit,
            COALESCE(wr.returns_loss, 0) AS returns_loss,
            ws.sales_profit - COALESCE(wr.returns_loss, 0) AS net_profit_after_returns
        FROM web_sales_agg ws
        LEFT JOIN web_returns_agg wr
            ON ws.year = wr.year AND ws.gender = wr.gender
    )
SELECT
    year,
    gender,
    'store'   AS channel,
    net_profit_after_returns
FROM store_combined
UNION ALL
SELECT
    year,
    gender,
    'catalog' AS channel,
    net_profit_after_returns
FROM catalog_combined
UNION ALL
SELECT
    year,
    gender,
    'web'     AS channel,
    net_profit_after_returns
FROM web_combined
ORDER BY year, gender, channel
