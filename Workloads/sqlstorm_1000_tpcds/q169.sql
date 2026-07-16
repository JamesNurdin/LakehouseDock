WITH sales_and_returns AS (
    SELECT d.d_date, i.i_category, cs.cs_net_profit AS net_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_date, i.i_category, -cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_date, i.i_category, ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_date, i.i_category, -sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_date, i.i_category, ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_date, i.i_category, -wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
daily_agg AS (
    SELECT d_date, i_category, SUM(net_amount) AS net_profit
    FROM sales_and_returns
    WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY d_date, i_category
),
daily_roll AS (
    SELECT
        d_date,
        i_category,
        net_profit,
        AVG(net_profit) OVER (PARTITION BY i_category ORDER BY d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS profit_7d_avg
    FROM daily_agg
)
SELECT
    year(d_date) AS d_year,
    i_category,
    SUM(net_profit) AS yearly_net_profit,
    MAX(profit_7d_avg) AS max_7day_avg_profit,
    RANK() OVER (PARTITION BY year(d_date) ORDER BY SUM(net_profit) DESC) AS category_rank
FROM daily_roll
GROUP BY year(d_date), i_category
ORDER BY d_year, category_rank
