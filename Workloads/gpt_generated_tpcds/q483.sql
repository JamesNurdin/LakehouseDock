WITH
    store_sales_agg AS (
        SELECT
            'store' AS channel,
            i.i_category AS category,
            d.d_year AS year,
            d.d_moy AS month,
            SUM(ss.ss_net_profit) AS profit,
            SUM(ss.ss_ext_sales_price) AS sales,
            CAST(0 AS decimal(15,2)) AS returns
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        GROUP BY i.i_category, d.d_year, d.d_moy
    ),
    store_returns_agg AS (
        SELECT
            'store' AS channel,
            i.i_category AS category,
            d.d_year AS year,
            d.d_moy AS month,
            CAST(0 AS decimal(15,2)) AS profit,
            CAST(0 AS decimal(15,2)) AS sales,
            SUM(sr.sr_return_amt) AS returns
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        GROUP BY i.i_category, d.d_year, d.d_moy
    ),
    catalog_sales_agg AS (
        SELECT
            'catalog' AS channel,
            i.i_category AS category,
            d.d_year AS year,
            d.d_moy AS month,
            SUM(cs.cs_net_profit) AS profit,
            SUM(cs.cs_ext_sales_price) AS sales,
            CAST(0 AS decimal(15,2)) AS returns
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        GROUP BY i.i_category, d.d_year, d.d_moy
    ),
    catalog_returns_agg AS (
        SELECT
            'catalog' AS channel,
            i.i_category AS category,
            d.d_year AS year,
            d.d_moy AS month,
            CAST(0 AS decimal(15,2)) AS profit,
            CAST(0 AS decimal(15,2)) AS sales,
            SUM(cr.cr_return_amount) AS returns
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        GROUP BY i.i_category, d.d_year, d.d_moy
    ),
    web_sales_agg AS (
        SELECT
            'web' AS channel,
            i.i_category AS category,
            d.d_year AS year,
            d.d_moy AS month,
            SUM(ws.ws_net_profit) AS profit,
            SUM(ws.ws_ext_sales_price) AS sales,
            CAST(0 AS decimal(15,2)) AS returns
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        GROUP BY i.i_category, d.d_year, d.d_moy
    ),
    web_returns_agg AS (
        SELECT
            'web' AS channel,
            i.i_category AS category,
            d.d_year AS year,
            d.d_moy AS month,
            CAST(0 AS decimal(15,2)) AS profit,
            CAST(0 AS decimal(15,2)) AS sales,
            SUM(wr.wr_return_amt) AS returns
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        GROUP BY i.i_category, d.d_year, d.d_moy
    ),
    combined AS (
        SELECT * FROM store_sales_agg
        UNION ALL
        SELECT * FROM store_returns_agg
        UNION ALL
        SELECT * FROM catalog_sales_agg
        UNION ALL
        SELECT * FROM catalog_returns_agg
        UNION ALL
        SELECT * FROM web_sales_agg
        UNION ALL
        SELECT * FROM web_returns_agg
    )
SELECT
    channel,
    category,
    year,
    month,
    SUM(profit) AS total_profit,
    SUM(sales) AS total_sales,
    SUM(returns) AS total_returns,
    CASE WHEN SUM(sales) = 0 THEN NULL
         ELSE ROUND(SUM(returns) / SUM(sales), 4) END AS return_rate
FROM combined
GROUP BY channel, category, year, month
ORDER BY channel, total_sales DESC, year, month
