WITH months AS (
    SELECT DISTINCT d.d_year AS year,
           month(d.d_date) AS month_num
    FROM date_dim d
),
store_sales_month AS (
    SELECT d.d_year AS year,
           month(d.d_date) AS month_num,
           sum(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, month(d.d_date)
),
store_returns_month AS (
    SELECT d.d_year AS year,
           month(d.d_date) AS month_num,
           sum(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, month(d.d_date)
),
catalog_sales_month AS (
    SELECT d.d_year AS year,
           month(d.d_date) AS month_num,
           sum(cs.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, month(d.d_date)
),
catalog_returns_month AS (
    SELECT d.d_year AS year,
           month(d.d_date) AS month_num,
           sum(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, month(d.d_date)
),
web_sales_month AS (
    SELECT d.d_year AS year,
           month(d.d_date) AS month_num,
           sum(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, month(d.d_date)
),
web_returns_month AS (
    SELECT d.d_year AS year,
           month(d.d_date) AS month_num,
           sum(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, month(d.d_date)
)
SELECT
    m.year,
    m.month_num AS month,
    ss.store_net_profit,
    sr.store_net_loss,
    cs.catalog_net_profit,
    cr.catalog_net_loss,
    ws.web_net_profit,
    wr.web_net_loss,
    (coalesce(ss.store_net_profit, 0) + coalesce(cs.catalog_net_profit, 0) + coalesce(ws.web_net_profit, 0)
     - coalesce(sr.store_net_loss, 0) - coalesce(cr.catalog_net_loss, 0) - coalesce(wr.web_net_loss, 0)) AS total_net_profit
FROM months m
LEFT JOIN store_sales_month ss ON m.year = ss.year AND m.month_num = ss.month_num
LEFT JOIN store_returns_month sr ON m.year = sr.year AND m.month_num = sr.month_num
LEFT JOIN catalog_sales_month cs ON m.year = cs.year AND m.month_num = cs.month_num
LEFT JOIN catalog_returns_month cr ON m.year = cr.year AND m.month_num = cr.month_num
LEFT JOIN web_sales_month ws ON m.year = ws.year AND m.month_num = ws.month_num
LEFT JOIN web_returns_month wr ON m.year = wr.year AND m.month_num = wr.month_num
WHERE m.year = 2001
ORDER BY m.year, m.month_num
