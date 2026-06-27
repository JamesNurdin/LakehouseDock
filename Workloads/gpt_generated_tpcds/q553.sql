WITH store_sales_monthly AS (
    SELECT
        d.d_year,
        d.d_moy,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy
),
store_returns_monthly AS (
    SELECT
        d.d_year,
        d.d_moy,
        'store' AS channel,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy
),
catalog_sales_monthly AS (
    SELECT
        d.d_year,
        d.d_moy,
        'catalog' AS channel,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy
),
catalog_returns_monthly AS (
    SELECT
        d.d_year,
        d.d_moy,
        'catalog' AS channel,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy
),
web_sales_monthly AS (
    SELECT
        d.d_year,
        d.d_moy,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy
),
web_returns_monthly AS (
    SELECT
        d.d_year,
        d.d_moy,
        'web' AS channel,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy
),
sales_combined AS (
    SELECT d_year, d_moy, channel, total_net_profit FROM store_sales_monthly
    UNION ALL
    SELECT d_year, d_moy, channel, total_net_profit FROM catalog_sales_monthly
    UNION ALL
    SELECT d_year, d_moy, channel, total_net_profit FROM web_sales_monthly
),
returns_combined AS (
    SELECT d_year, d_moy, channel, total_return_loss FROM store_returns_monthly
    UNION ALL
    SELECT d_year, d_moy, channel, total_return_loss FROM catalog_returns_monthly
    UNION ALL
    SELECT d_year, d_moy, channel, total_return_loss FROM web_returns_monthly
)
SELECT
    s.d_year,
    s.d_moy,
    s.channel,
    s.total_net_profit,
    r.total_return_loss,
    CASE WHEN s.total_net_profit = 0 THEN NULL ELSE r.total_return_loss / s.total_net_profit END AS return_loss_ratio
FROM sales_combined s
LEFT JOIN returns_combined r
    ON s.d_year = r.d_year
    AND s.d_moy = r.d_moy
    AND s.channel = r.channel
ORDER BY s.d_year, s.d_moy, s.channel
