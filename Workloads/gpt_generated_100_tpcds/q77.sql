/*
   Net profit by year, product category and sales channel (store, catalog, web).
   Store channel profit is adjusted for returned items (store_returns).
*/
WITH store_channel AS (
    SELECT
        d.d_year,
        i.i_category,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
        SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) AS net_profit_after_returns
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    GROUP BY d.d_year, i.i_category
),
catalog_channel AS (
    SELECT
        d.d_year,
        i.i_category,
        'catalog' AS channel,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        0 AS total_return_loss,
        SUM(cs.cs_net_profit) AS net_profit_after_returns
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
),
web_channel AS (
    SELECT
        d.d_year,
        i.i_category,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        0 AS total_return_loss,
        SUM(ws.ws_net_profit) AS net_profit_after_returns
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
)
SELECT
    d_year,
    i_category,
    channel,
    total_sales_profit,
    total_return_loss,
    net_profit_after_returns
FROM store_channel
UNION ALL
SELECT
    d_year,
    i_category,
    channel,
    total_sales_profit,
    total_return_loss,
    net_profit_after_returns
FROM catalog_channel
UNION ALL
SELECT
    d_year,
    i_category,
    channel,
    total_sales_profit,
    total_return_loss,
    net_profit_after_returns
FROM web_channel
ORDER BY d_year, i_category, channel
