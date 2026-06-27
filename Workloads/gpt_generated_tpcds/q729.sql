WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2022-01-01' AND d.d_date < DATE '2023-01-01'
),
returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_date >= DATE '2022-01-01' AND d_ret.d_date < DATE '2023-01-01'
),
item_dim AS (
    SELECT i_item_sk, i_category
    FROM item
),
cust_demo AS (
    SELECT c.c_customer_sk, cd.cd_gender
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    cd.cd_gender,
    SUM(s.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(r.wr_net_loss, 0)) AS total_net_loss,
    SUM(s.ws_quantity) AS total_quantity_sold,
    SUM(COALESCE(r.wr_return_quantity, 0)) AS total_quantity_returned
FROM sales s
JOIN date_dim d ON s.ws_sold_date_sk = d.d_date_sk
JOIN item_dim i ON s.ws_item_sk = i.i_item_sk
JOIN cust_demo cd ON s.ws_bill_customer_sk = cd.c_customer_sk
LEFT JOIN returns r ON s.ws_order_number = r.wr_order_number AND s.ws_item_sk = r.wr_item_sk
GROUP BY d.d_year, d.d_month_seq, i.i_category, cd.cd_gender
ORDER BY d.d_year, d.d_month_seq, i.i_category, cd.cd_gender
