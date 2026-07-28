WITH
sales_by_year AS (
    SELECT
        d1.d_year,
        ws_site.web_name,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM web_sales ws
    JOIN date_dim d1
        ON ws.ws_sold_date_sk = d1.d_date_sk
    JOIN time_dim t_sales
        ON ws.ws_sold_time_sk = t_sales.t_time_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    GROUP BY d1.d_year, ws_site.web_name
    HAVING SUM(ws.ws_net_profit) > 10000
),
returns_by_year AS (
    SELECT
        d2.d_year,
        r.r_reason_desc,
        SUM(wr.wr_net_loss) AS total_web_return_loss
    FROM web_returns wr
    JOIN date_dim d2
        ON wr.wr_returned_date_sk = d2.d_date_sk
    JOIN time_dim t_ret
        ON wr.wr_returned_time_sk = t_ret.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY d2.d_year, r.r_reason_desc
),
catalog_ret_by_year AS (
    SELECT
        d3.d_year,
        r2.r_reason_desc AS catalog_reason,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss
    FROM catalog_returns cr
    JOIN date_dim d3
        ON cr.cr_returned_date_sk = d3.d_date_sk
    JOIN time_dim t_cat
        ON cr.cr_returned_time_sk = t_cat.t_time_sk
    JOIN reason r2
        ON cr.cr_reason_sk = r2.r_reason_sk
    GROUP BY d3.d_year, r2.r_reason_desc
)
SELECT
    s.d_year,
    s.web_name,
    s.total_web_profit,
    r.r_reason_desc,
    r.total_web_return_loss,
    c.catalog_reason,
    c.total_catalog_return_loss
FROM sales_by_year s
LEFT JOIN returns_by_year r
    ON s.d_year = r.d_year
LEFT JOIN catalog_ret_by_year c
    ON s.d_year = c.d_year
WHERE s.total_web_profit > 20000
ORDER BY s.d_year DESC, s.total_web_profit DESC
LIMIT 100
