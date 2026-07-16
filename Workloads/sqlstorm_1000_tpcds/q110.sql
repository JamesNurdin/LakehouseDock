WITH sales AS (
    SELECT cs.cs_item_sk AS item_sk,
           d.d_year,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT ss.ss_item_sk,
           d.d_year,
           ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT ws.ws_item_sk,
           d.d_year,
           ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
), returns AS (
    SELECT cr.cr_item_sk AS item_sk,
           d.d_year,
           -cr.cr_net_loss AS net_profit
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    UNION ALL
    SELECT sr.sr_item_sk,
           d.d_year,
           -sr.sr_net_loss AS net_profit
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    UNION ALL
    SELECT wr.wr_item_sk,
           d.d_year,
           -wr.wr_net_loss AS net_profit
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
), combined AS (
    SELECT item_sk,
           d_year,
           SUM(net_profit) AS total_profit
    FROM (
        SELECT * FROM sales
        UNION ALL
        SELECT * FROM returns
    ) t
    GROUP BY item_sk, d_year
)
SELECT i.i_item_id,
       i.i_product_name,
       c.d_year,
       c.total_profit
FROM combined c
JOIN item i ON c.item_sk = i.i_item_sk
WHERE c.d_year = 2001
ORDER BY c.total_profit DESC
LIMIT 100
