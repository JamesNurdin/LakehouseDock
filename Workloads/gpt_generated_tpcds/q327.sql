WITH web_sales_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        i.i_category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_returns_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        i.i_category,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(wr.wr_return_quantity) AS total_return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
store_returns_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        i.i_category,
        SUM(sr.sr_return_amt) AS total_store_return_amount,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        SUM(sr.sr_return_quantity) AS total_store_return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    ws.d_year,
    ws.month,
    ws.i_category,
    ws.total_sales,
    COALESCE(wr.total_return_amount, 0) AS total_web_return_amount,
    COALESCE(sr.total_store_return_amount, 0) AS total_store_return_amount,
    ws.total_sales - COALESCE(wr.total_return_amount, 0) - COALESCE(sr.total_store_return_amount, 0) AS net_sales,
    ws.total_profit - COALESCE(wr.total_return_loss, 0) - COALESCE(sr.total_store_return_loss, 0) AS net_profit,
    ws.total_quantity - COALESCE(wr.total_return_quantity, 0) - COALESCE(sr.total_store_return_quantity, 0) AS net_quantity
FROM web_sales_monthly ws
LEFT JOIN web_returns_monthly wr
    ON ws.d_year = wr.d_year
    AND ws.month = wr.month
    AND ws.i_category = wr.i_category
LEFT JOIN store_returns_monthly sr
    ON ws.d_year = sr.d_year
    AND ws.month = sr.month
    AND ws.i_category = sr.i_category
ORDER BY ws.d_year, ws.month, ws.i_category
