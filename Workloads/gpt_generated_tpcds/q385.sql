WITH store_sales_month AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        SUM(ss.ss_net_paid_inc_tax) AS store_sales_net_paid,
        SUM(ss.ss_net_profit) AS store_sales_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
store_returns_month AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        SUM(sr.sr_net_loss) AS store_returns_loss
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
catalog_sales_month AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        SUM(cs.cs_net_paid_inc_tax) AS catalog_sales_net_paid,
        SUM(cs.cs_net_profit) AS catalog_sales_profit
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
catalog_returns_month AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        SUM(cr.cr_net_loss) AS catalog_returns_loss
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
web_sales_month AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        SUM(ws.ws_net_paid_inc_tax) AS web_sales_net_paid,
        SUM(ws.ws_net_profit) AS web_sales_profit
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
web_returns_month AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        SUM(wr.wr_net_loss) AS web_returns_loss
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    s.d_year,
    s.month,
    s.store_sales_net_paid,
    s.store_sales_profit,
    r.store_returns_loss,
    c.catalog_sales_net_paid,
    c.catalog_sales_profit,
    cr.catalog_returns_loss,
    w.web_sales_net_paid,
    w.web_sales_profit,
    wr.web_returns_loss,
    ( s.store_sales_profit
      - COALESCE(r.store_returns_loss, 0)
      + c.catalog_sales_profit
      - COALESCE(cr.catalog_returns_loss, 0)
      + w.web_sales_profit
      - COALESCE(wr.web_returns_loss, 0)
    ) AS total_net_profit
FROM store_sales_month s
LEFT JOIN store_returns_month r
    ON s.d_year = r.d_year AND s.month = r.month
LEFT JOIN catalog_sales_month c
    ON s.d_year = c.d_year AND s.month = c.month
LEFT JOIN catalog_returns_month cr
    ON s.d_year = cr.d_year AND s.month = cr.month
LEFT JOIN web_sales_month w
    ON s.d_year = w.d_year AND s.month = w.month
LEFT JOIN web_returns_month wr
    ON s.d_year = wr.d_year AND s.month = wr.month
WHERE s.d_year = 2001
ORDER BY s.d_year, s.month
