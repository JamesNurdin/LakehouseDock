WITH catalog_sales_agg AS (
    SELECT
        d.d_year,
        cp.cp_department,
        SUM(cs.cs_net_profit) AS total_sales_profit
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, cp.cp_department
),
catalog_returns_agg AS (
    SELECT
        d.d_year,
        cp.cp_department,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, cp.cp_department
),
catalog_net AS (
    SELECT
        cs.d_year,
        cs.cp_department AS dimension,
        cs.total_sales_profit - COALESCE(cr.total_return_loss, 0) AS net_profit,
        'catalog' AS channel
    FROM catalog_sales_agg cs
    LEFT JOIN catalog_returns_agg cr
        ON cs.d_year = cr.d_year
        AND cs.cp_department = cr.cp_department
),
web_sales_agg AS (
    SELECT
        d.d_year,
        w.web_name,
        SUM(ws.ws_net_profit) AS total_sales_profit
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, w.web_name
),
web_returns_agg AS (
    SELECT
        d.d_year,
        w.web_name,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, w.web_name
),
web_net AS (
    SELECT
        ws.d_year,
        ws.web_name AS dimension,
        ws.total_sales_profit - COALESCE(wr.total_return_loss, 0) AS net_profit,
        'web' AS channel
    FROM web_sales_agg ws
    LEFT JOIN web_returns_agg wr
        ON ws.d_year = wr.d_year
        AND ws.web_name = wr.web_name
)
SELECT
    t.year,
    t.channel,
    t.dimension,
    t.net_profit
FROM (
    SELECT cs.d_year AS year, cs.dimension, cs.net_profit, cs.channel FROM catalog_net cs
    UNION ALL
    SELECT ws.d_year AS year, ws.dimension, ws.net_profit, ws.channel FROM web_net ws
) t
ORDER BY t.year, t.channel, t.dimension
