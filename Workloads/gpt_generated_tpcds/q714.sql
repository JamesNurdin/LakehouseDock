WITH web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
store_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        SUM(sr.sr_return_amt) AS total_store_return_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        SUM(wr.wr_return_amt) AS total_web_return_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.total_sales,
    COALESCE(sr.total_store_return_amount, 0) AS store_return_amount,
    COALESCE(wr.total_web_return_amount, 0) AS web_return_amount,
    s.total_sales - COALESCE(sr.total_store_return_amount, 0) - COALESCE(wr.total_web_return_amount, 0) AS net_revenue,
    s.total_profit - COALESCE(sr.total_store_return_loss, 0) - COALESCE(wr.total_web_return_loss, 0) AS net_profit
FROM web_sales_agg s
LEFT JOIN store_returns_agg sr
    ON s.d_year = sr.d_year
    AND s.d_month_seq = sr.d_month_seq
    AND s.i_category = sr.i_category
LEFT JOIN web_returns_agg wr
    ON s.d_year = wr.d_year
    AND s.d_month_seq = wr.d_month_seq
    AND s.i_category = wr.i_category
ORDER BY s.d_year, s.d_month_seq, s.i_category
