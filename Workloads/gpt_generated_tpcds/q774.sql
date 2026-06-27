WITH store_sales_agg AS (
    SELECT
        ds.d_year AS year,
        ds.d_moy AS month,
        i.i_category AS category,
        'store' AS channel,
        SUM(ss.ss_net_paid) AS sales_amount,
        0.0 AS returns_amount
    FROM store_sales ss
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY ds.d_year, ds.d_moy, i.i_category
),
store_returns_agg AS (
    SELECT
        dr.d_year AS year,
        dr.d_moy AS month,
        i.i_category AS category,
        'store' AS channel,
        0.0 AS sales_amount,
        SUM(sr.sr_net_loss) AS returns_amount
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY dr.d_year, dr.d_moy, i.i_category
),
catalog_sales_agg AS (
    SELECT
        ds.d_year AS year,
        ds.d_moy AS month,
        i.i_category AS category,
        'catalog' AS channel,
        SUM(cs.cs_net_paid) AS sales_amount,
        0.0 AS returns_amount
    FROM catalog_sales cs
    JOIN date_dim ds ON cs.cs_sold_date_sk = ds.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY ds.d_year, ds.d_moy, i.i_category
),
catalog_returns_agg AS (
    SELECT
        dr.d_year AS year,
        dr.d_moy AS month,
        i.i_category AS category,
        'catalog' AS channel,
        0.0 AS sales_amount,
        SUM(cr.cr_net_loss) AS returns_amount
    FROM catalog_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY dr.d_year, dr.d_moy, i.i_category
),
web_sales_agg AS (
    SELECT
        ds.d_year AS year,
        ds.d_moy AS month,
        i.i_category AS category,
        'web' AS channel,
        SUM(ws.ws_net_paid) AS sales_amount,
        0.0 AS returns_amount
    FROM web_sales ws
    JOIN date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY ds.d_year, ds.d_moy, i.i_category
),
web_returns_agg AS (
    SELECT
        dr.d_year AS year,
        dr.d_moy AS month,
        i.i_category AS category,
        'web' AS channel,
        0.0 AS sales_amount,
        SUM(wr.wr_net_loss) AS returns_amount
    FROM web_returns wr
    JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY dr.d_year, dr.d_moy, i.i_category
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
    year,
    month,
    category,
    channel,
    SUM(sales_amount) AS total_sales,
    SUM(returns_amount) AS total_returns,
    SUM(sales_amount) - SUM(returns_amount) AS net_profit
FROM combined
WHERE year = 2000
GROUP BY year, month, category, channel
ORDER BY year, month, category, channel
