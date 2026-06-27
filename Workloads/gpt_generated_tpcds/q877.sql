WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        cd_s.cd_gender,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_transactions,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd_s
        ON ws.ws_bill_cdemo_sk = cd_s.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY d.d_year, d.d_month_seq, i.i_category, cd_s.cd_gender
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        cd_r.cd_gender,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS return_transactions
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_r
        ON wr.wr_refunded_cdemo_sk = cd_r.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY d.d_year, d.d_month_seq, i.i_category, cd_r.cd_gender
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.cd_gender,
    s.total_net_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_net_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    s.sales_transactions,
    COALESCE(r.return_transactions, 0) AS return_transactions,
    s.total_discount,
    CASE
        WHEN s.total_net_profit = 0 THEN 0
        ELSE (s.total_net_profit - COALESCE(r.total_return_loss, 0)) / s.total_net_profit
    END AS profit_retention_ratio
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.i_category = r.i_category
    AND s.cd_gender = r.cd_gender
ORDER BY s.d_year, s.d_month_seq, s.i_category, s.cd_gender
