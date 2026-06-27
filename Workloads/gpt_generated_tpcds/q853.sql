WITH catalog_sales_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_sales_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_returns_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    COALESCE(cs.d_year, ws.d_year, cr.d_year) AS year,
    COALESCE(cs.d_month_seq, ws.d_month_seq, cr.d_month_seq) AS month_seq,
    COALESCE(cs.i_category, ws.i_category, cr.i_category) AS category,
    cs.catalog_net_profit,
    ws.web_net_profit,
    cr.total_return_amount,
    (COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) - COALESCE(cr.total_return_loss, 0)) AS net_profit_after_returns
FROM catalog_sales_monthly cs
FULL OUTER JOIN web_sales_monthly ws
    ON cs.d_year = ws.d_year
   AND cs.d_month_seq = ws.d_month_seq
   AND cs.i_category = ws.i_category
FULL OUTER JOIN catalog_returns_monthly cr
    ON COALESCE(cs.d_year, ws.d_year) = cr.d_year
   AND COALESCE(cs.d_month_seq, ws.d_month_seq) = cr.d_month_seq
   AND COALESCE(cs.i_category, ws.i_category) = cr.i_category
ORDER BY year, month_seq, category
