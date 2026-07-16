WITH sales AS (
    -- Store sales (positive profit)
    SELECT i.i_category AS i_category,
           d.d_year AS d_year,
           d.d_moy AS month,
           ss.ss_net_profit AS net_amount
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk

    UNION ALL

    -- Web sales (positive profit)
    SELECT i.i_category,
           d.d_year,
           d.d_moy,
           ws.ws_net_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk

    UNION ALL

    -- Store returns (negative profit)
    SELECT i.i_category,
           d.d_year,
           d.d_moy,
           -sr.sr_net_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk

    UNION ALL

    -- Web returns (negative profit)
    SELECT i.i_category,
           d.d_year,
           d.d_moy,
           -wr.wr_net_loss
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
)
SELECT s.i_category,
       s.d_year,
       s.month,
       sum(s.net_amount) AS net_profit
FROM sales s
WHERE s.d_year = 2001
GROUP BY s.i_category, s.d_year, s.month
ORDER BY net_profit DESC
LIMIT 10
