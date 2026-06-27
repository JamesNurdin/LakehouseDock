WITH store_sales_data AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           ss.ss_net_profit AS net_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
),
store_returns_data AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           -sr.sr_net_loss AS net_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
),
catalog_sales_data AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           cs.cs_net_profit AS net_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
),
catalog_returns_data AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           -cr.cr_net_loss AS net_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
),
web_sales_data AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           ws.ws_net_profit AS net_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
web_returns_data AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           -wr.wr_net_loss AS net_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
combined AS (
    SELECT year, category, net_amount FROM store_sales_data
    UNION ALL
    SELECT year, category, net_amount FROM store_returns_data
    UNION ALL
    SELECT year, category, net_amount FROM catalog_sales_data
    UNION ALL
    SELECT year, category, net_amount FROM catalog_returns_data
    UNION ALL
    SELECT year, category, net_amount FROM web_sales_data
    UNION ALL
    SELECT year, category, net_amount FROM web_returns_data
)
SELECT year,
       category,
       SUM(net_amount) AS net_profit_after_returns,
       SUM(CASE WHEN net_amount > 0 THEN net_amount ELSE 0 END) AS total_profit,
       SUM(CASE WHEN net_amount < 0 THEN -net_amount ELSE 0 END) AS total_loss
FROM combined
GROUP BY year, category
ORDER BY year, net_profit_after_returns DESC
