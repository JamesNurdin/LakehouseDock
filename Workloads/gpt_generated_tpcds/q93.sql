-- Top 10 items by net profit (sales minus returns) per month for 2022 across all channels
WITH store_sales_agg AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        ss.ss_sold_date_sk AS date_sk,
        d.d_year,
        d.d_moy AS month_of_year,
        ss.ss_net_profit AS net_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        cs.cs_sold_date_sk AS date_sk,
        d.d_year,
        d.d_moy AS month_of_year,
        cs.cs_net_profit AS net_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        ws.ws_sold_date_sk AS date_sk,
        d.d_year,
        d.d_moy AS month_of_year,
        ws.ws_net_profit AS net_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
store_returns_agg AS (
    SELECT
        sr.sr_item_sk AS item_sk,
        sr.sr_returned_date_sk AS date_sk,
        d.d_year,
        d.d_moy AS month_of_year,
        -sr.sr_net_loss AS net_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
),
catalog_returns_agg AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        cr.cr_returned_date_sk AS date_sk,
        d.d_year,
        d.d_moy AS month_of_year,
        -cr.cr_net_loss AS net_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
),
web_returns_agg AS (
    SELECT
        wr.wr_item_sk AS item_sk,
        wr.wr_returned_date_sk AS date_sk,
        d.d_year,
        d.d_moy AS month_of_year,
        -wr.wr_net_loss AS net_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
),
combined AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
    UNION ALL
    SELECT * FROM store_returns_agg
    UNION ALL
    SELECT * FROM catalog_returns_agg
    UNION ALL
    SELECT * FROM web_returns_agg
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    c.d_year,
    c.month_of_year,
    SUM(c.net_amount) AS total_net_profit
FROM combined c
JOIN item i ON c.item_sk = i.i_item_sk
WHERE c.d_year = 2022
GROUP BY i.i_item_id, i.i_item_desc, c.d_year, c.month_of_year
ORDER BY total_net_profit DESC
LIMIT 10
