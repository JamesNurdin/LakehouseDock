WITH store AS (
    SELECT
        i.i_category AS i_category,
        d.d_year AS d_year,
        ss.ss_net_profit AS profit,
        COALESCE(sr.sr_net_loss, 0) AS loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    WHERE d.d_year = 2001
),
web AS (
    SELECT
        i.i_category AS i_category,
        d.d_year AS d_year,
        ws.ws_net_profit AS profit,
        COALESCE(wr.wr_net_loss, 0) AS loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    WHERE d.d_year = 2001
),
catalog AS (
    SELECT
        i.i_category AS i_category,
        d.d_year AS d_year,
        cs.cs_net_profit AS profit,
        COALESCE(cr.cr_net_loss, 0) AS loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    WHERE d.d_year = 2001
)
SELECT
    category,
    year,
    SUM(profit) AS total_profit,
    SUM(loss) AS total_loss,
    SUM(profit) - SUM(loss) AS net_profit
FROM (
    SELECT i_category AS category, d_year AS year, profit, loss FROM store
    UNION ALL
    SELECT i_category AS category, d_year AS year, profit, loss FROM web
    UNION ALL
    SELECT i_category AS category, d_year AS year, profit, loss FROM catalog
) combined
GROUP BY category, year
ORDER BY net_profit DESC
LIMIT 10
