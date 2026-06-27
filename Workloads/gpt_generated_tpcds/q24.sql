WITH
store_sales_2001 AS (
    SELECT i.i_brand AS brand,
           ss.ss_net_profit AS net_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),
store_returns_2001 AS (
    SELECT i.i_brand AS brand,
           -sr.sr_net_loss AS net_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),
catalog_sales_2001 AS (
    SELECT i.i_brand AS brand,
           cs.cs_net_profit AS net_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),
catalog_returns_2001 AS (
    SELECT i.i_brand AS brand,
           -cr.cr_net_loss AS net_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),
web_sales_2001 AS (
    SELECT i.i_brand AS brand,
           ws.ws_net_profit AS net_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),
web_returns_2001 AS (
    SELECT i.i_brand AS brand,
           -wr.wr_net_loss AS net_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
)
SELECT
    brand,
    SUM(net_amount) AS net_profit_after_returns
FROM (
    SELECT * FROM store_sales_2001
    UNION ALL
    SELECT * FROM store_returns_2001
    UNION ALL
    SELECT * FROM catalog_sales_2001
    UNION ALL
    SELECT * FROM catalog_returns_2001
    UNION ALL
    SELECT * FROM web_sales_2001
    UNION ALL
    SELECT * FROM web_returns_2001
) t
GROUP BY brand
ORDER BY net_profit_after_returns DESC
LIMIT 10
