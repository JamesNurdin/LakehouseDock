WITH sales AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_quantity,
        ws_net_paid,
        ws_net_profit,
        ws_bill_customer_sk,
        ws_bill_cdemo_sk,
        ws_bill_hdemo_sk
    FROM web_sales
),
returns AS (
    SELECT
        wr_order_number,
        wr_item_sk,
        wr_returned_date_sk,
        wr_returned_time_sk,
        wr_return_quantity,
        wr_return_amt,
        wr_reason_sk,
        wr_refunded_customer_sk,
        wr_refunded_cdemo_sk,
        wr_refunded_hdemo_sk
    FROM web_returns
)
SELECT
    d_sales.d_year,
    d_sales.d_month_seq,
    cd.cd_gender,
    cd.cd_marital_status,
    hd.hd_buy_potential,
    SUM(s.ws_net_paid) AS total_net_paid,
    SUM(s.ws_net_profit) AS total_net_profit,
    SUM(r.wr_return_amt) AS total_return_amount,
    CASE WHEN SUM(s.ws_net_paid) = 0 THEN 0 ELSE SUM(r.wr_return_amt) / SUM(s.ws_net_paid) END AS return_rate
FROM sales s
JOIN date_dim d_sales ON s.ws_sold_date_sk = d_sales.d_date_sk
JOIN customer_demographics cd ON s.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON s.ws_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN returns r ON s.ws_order_number = r.wr_order_number AND s.ws_item_sk = r.wr_item_sk
LEFT JOIN date_dim d_return ON r.wr_returned_date_sk = d_return.d_date_sk
WHERE d_sales.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
GROUP BY d_sales.d_year, d_sales.d_month_seq, cd.cd_gender, cd.cd_marital_status, hd.hd_buy_potential
ORDER BY d_sales.d_year, d_sales.d_month_seq, cd.cd_gender, cd.cd_marital_status, hd.hd_buy_potential
