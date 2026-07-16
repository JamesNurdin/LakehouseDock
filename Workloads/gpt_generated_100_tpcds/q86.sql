WITH cat_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        sm.sm_type AS ship_mode_type,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
),
cat_returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        sm.sm_type AS ship_mode_type,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
),
web_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        sm.sm_type AS ship_mode_type,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
),
web_returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        CAST(NULL AS varchar) AS ship_mode_type,
        wr.wr_return_amt AS return_amount,
        wr.wr_net_loss AS return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
)
SELECT
    t.d_year,
    t.d_month_seq,
    t.i_category,
    t.ship_mode_type,
    SUM(t.sales_amount) AS total_sales_amount,
    SUM(t.return_amount) AS total_return_amount,
    SUM(t.profit) AS total_sales_profit,
    SUM(t.return_loss) AS total_return_loss
FROM (
    SELECT d_year, d_month_seq, i_category, ship_mode_type,
           sales_amount, 0.0 AS return_amount,
           profit, 0.0 AS return_loss
    FROM cat_sales
    UNION ALL
    SELECT d_year, d_month_seq, i_category, ship_mode_type,
           0.0, return_amount,
           0.0, return_loss
    FROM cat_returns
    UNION ALL
    SELECT d_year, d_month_seq, i_category, ship_mode_type,
           sales_amount, 0.0,
           profit, 0.0
    FROM web_sales
    UNION ALL
    SELECT d_year, d_month_seq, i_category, ship_mode_type,
           0.0, return_amount,
           0.0, return_loss
    FROM web_returns
) t
WHERE t.d_year = 2001
GROUP BY t.d_year, t.d_month_seq, t.i_category, t.ship_mode_type
ORDER BY t.d_year, t.d_month_seq, t.i_category, t.ship_mode_type
