WITH sales AS (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        i.i_category AS i_category,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales_net,
        SUM(cs.cs_net_profit) AS total_sales_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_ret AS (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        i.i_category AS i_category,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_ret AS (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        i.i_category AS i_category,
        SUM(wr.wr_net_loss) AS total_web_return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.total_sales_net,
    s.total_sales_profit,
    COALESCE(cr.total_catalog_return_loss, 0) AS total_catalog_return_loss,
    COALESCE(wr.total_web_return_loss, 0) AS total_web_return_loss,
    s.total_sales_profit - COALESCE(cr.total_catalog_return_loss, 0) - COALESCE(wr.total_web_return_loss, 0) AS net_profit_after_returns
FROM sales s
LEFT JOIN catalog_ret cr
    ON s.d_year = cr.d_year
    AND s.d_month_seq = cr.d_month_seq
    AND s.i_category = cr.i_category
LEFT JOIN web_ret wr
    ON s.d_year = wr.d_year
    AND s.d_month_seq = wr.d_month_seq
    AND s.i_category = wr.i_category
ORDER BY s.d_year, s.d_month_seq, s.i_category
