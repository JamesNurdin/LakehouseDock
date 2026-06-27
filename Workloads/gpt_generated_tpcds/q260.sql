WITH sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_sales_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_category
),
store_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_category
),
catalog_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_category
),
web_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_category
),
all_returns AS (
    SELECT
        d_year,
        d_month_seq,
        i_category,
        SUM(total_return_loss) AS total_return_loss
    FROM (
        SELECT d_year, d_month_seq, i_category, total_return_loss FROM store_returns_agg
        UNION ALL
        SELECT d_year, d_month_seq, i_category, total_return_loss FROM catalog_returns_agg
        UNION ALL
        SELECT d_year, d_month_seq, i_category, total_return_loss FROM web_returns_agg
    )
    GROUP BY
        d_year,
        d_month_seq,
        i_category
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.total_sales_amount,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns
FROM sales s
LEFT JOIN all_returns r
    ON s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.i_category = r.i_category
ORDER BY
    s.d_year,
    s.d_month_seq,
    s.i_category
