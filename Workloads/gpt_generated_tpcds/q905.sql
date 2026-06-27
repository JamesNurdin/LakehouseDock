WITH sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_category,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY d.d_year, d.d_month_seq, i.i_category, cd.cd_gender
),
returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_category,
        cd.cd_gender,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_quantity_returned,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY d.d_year, d.d_month_seq, i.i_category, cd.cd_gender
)
SELECT
    CONCAT(CAST(s.year AS VARCHAR), '-', LPAD(CAST(s.month_seq AS VARCHAR), 2, '0')) AS year_month,
    s.i_category,
    s.cd_gender,
    s.total_sales_amount,
    s.total_quantity_sold,
    s.total_net_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_quantity_returned, 0) AS total_quantity_returned,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    (s.total_net_profit - COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.year = r.year
   AND s.month_seq = r.month_seq
   AND s.i_category = r.i_category
   AND s.cd_gender = r.cd_gender
ORDER BY s.year, s.month_seq, s.i_category, s.cd_gender
