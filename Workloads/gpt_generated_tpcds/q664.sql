WITH catalog_sales_data AS (
    SELECT
        d.d_year AS d_year,
        i.i_category AS i_category,
        cs.cs_net_profit AS profit,
        CAST(0 AS decimal(15,2)) AS loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
web_sales_data AS (
    SELECT
        d.d_year AS d_year,
        i.i_category AS i_category,
        ws.ws_net_profit AS profit,
        CAST(0 AS decimal(15,2)) AS loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
catalog_returns_data AS (
    SELECT
        d.d_year AS d_year,
        i.i_category AS i_category,
        CAST(0 AS decimal(15,2)) AS profit,
        cr.cr_net_loss AS loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
web_returns_data AS (
    SELECT
        d.d_year AS d_year,
        i.i_category AS i_category,
        CAST(0 AS decimal(15,2)) AS profit,
        wr.wr_net_loss AS loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
combined AS (
    SELECT d_year, i_category, profit, loss FROM catalog_sales_data
    UNION ALL
    SELECT d_year, i_category, profit, loss FROM web_sales_data
    UNION ALL
    SELECT d_year, i_category, profit, loss FROM catalog_returns_data
    UNION ALL
    SELECT d_year, i_category, profit, loss FROM web_returns_data
)
SELECT
    d_year,
    i_category,
    SUM(profit) AS total_sales_profit,
    SUM(loss) AS total_return_loss,
    SUM(profit) - SUM(loss) AS net_profit
FROM combined
GROUP BY d_year, i_category
ORDER BY net_profit DESC
LIMIT 10
