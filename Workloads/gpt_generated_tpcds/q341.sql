WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_date AS sale_date,
        d.d_year AS sale_year
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
),
returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        wr.wr_net_loss,
        cd.cd_gender AS return_gender,
        cd.cd_marital_status AS return_marital_status,
        d_ret.d_date AS return_date,
        d_ret.d_year AS return_year
    FROM web_returns wr
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2000
)
SELECT
    date_format(s.sale_date, '%Y-%m') AS year_month,
    s.cd_gender,
    s.cd_marital_status,
    SUM(s.ws_net_profit) AS total_sales_profit,
    COALESCE(SUM(r.wr_net_loss), 0) AS total_return_loss,
    SUM(s.ws_net_profit) - COALESCE(SUM(r.wr_net_loss), 0) AS net_profit_after_returns
FROM sales s
LEFT JOIN returns r
    ON s.ws_order_number = r.wr_order_number
   AND s.ws_item_sk = r.wr_item_sk
GROUP BY
    date_format(s.sale_date, '%Y-%m'),
    s.cd_gender,
    s.cd_marital_status
ORDER BY
    year_month DESC,
    net_profit_after_returns DESC
