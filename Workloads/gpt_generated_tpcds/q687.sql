WITH catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cs.cs_net_profit) AS total_catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cr.cr_net_loss) AS total_catalog_returns_loss
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(wr.wr_net_loss) AS total_web_returns_loss
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    COALESCE(cs.d_year, cr.d_year, ws.d_year, wr.d_year) AS d_year,
    COALESCE(cs.d_month_seq, cr.d_month_seq, ws.d_month_seq, wr.d_month_seq) AS d_month_seq,
    COALESCE(cs.i_category, cr.i_category, ws.i_category, wr.i_category) AS i_category,
    COALESCE(cs.total_catalog_profit, 0) - COALESCE(cr.total_catalog_returns_loss, 0) AS net_catalog_profit,
    COALESCE(ws.total_web_profit, 0) - COALESCE(wr.total_web_returns_loss, 0) AS net_web_profit,
    (COALESCE(cs.total_catalog_profit, 0) - COALESCE(cr.total_catalog_returns_loss, 0))
      + (COALESCE(ws.total_web_profit, 0) - COALESCE(wr.total_web_returns_loss, 0)) AS total_net_profit,
    RANK() OVER (
        PARTITION BY COALESCE(cs.d_year, cr.d_year, ws.d_year, wr.d_year),
                     COALESCE(cs.d_month_seq, cr.d_month_seq, ws.d_month_seq, wr.d_month_seq)
        ORDER BY (COALESCE(cs.total_catalog_profit, 0) - COALESCE(cr.total_catalog_returns_loss, 0))
                 + (COALESCE(ws.total_web_profit, 0) - COALESCE(wr.total_web_returns_loss, 0)) DESC
    ) AS profit_rank
FROM catalog_sales_agg cs
FULL OUTER JOIN catalog_returns_agg cr
    ON cs.d_year = cr.d_year
    AND cs.d_month_seq = cr.d_month_seq
    AND cs.i_category = cr.i_category
FULL OUTER JOIN web_sales_agg ws
    ON COALESCE(cs.d_year, cr.d_year) = ws.d_year
    AND COALESCE(cs.d_month_seq, cr.d_month_seq) = ws.d_month_seq
    AND COALESCE(cs.i_category, cr.i_category) = ws.i_category
FULL OUTER JOIN web_returns_agg wr
    ON COALESCE(cs.d_year, cr.d_year, ws.d_year) = wr.d_year
    AND COALESCE(cs.d_month_seq, cr.d_month_seq, ws.d_month_seq) = wr.d_month_seq
    AND COALESCE(cs.i_category, cr.i_category, ws.i_category) = wr.i_category
ORDER BY d_year, d_month_seq, total_net_profit DESC
