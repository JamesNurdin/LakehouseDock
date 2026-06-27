WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_addr_sk,
        d_sales.d_date AS sales_date,
        i.i_category,
        cd.cd_gender,
        ca.ca_state
    FROM web_sales ws
    JOIN date_dim d_sales
        ON ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d_sales.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        d_return.d_date AS return_date,
        i.i_category,
        cd.cd_gender,
        ca.ca_state
    FROM web_returns wr
    JOIN date_dim d_return
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    WHERE d_return.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
)
SELECT
    date_format(sales.sales_date, '%Y-%m') AS year_month,
    sales.i_category,
    sales.cd_gender,
    sales.ca_state,
    SUM(sales.ws_ext_sales_price) AS total_sales_amount,
    SUM(sales.ws_quantity) AS total_units_sold,
    SUM(sales.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(returns.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(returns.wr_return_quantity, 0)) AS total_units_returned,
    SUM(COALESCE(returns.wr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT sales.ws_bill_customer_sk) AS distinct_customers
FROM sales
LEFT JOIN returns
    ON sales.ws_order_number = returns.wr_order_number
   AND sales.ws_item_sk = returns.wr_item_sk
GROUP BY
    date_format(sales.sales_date, '%Y-%m'),
    sales.i_category,
    sales.cd_gender,
    sales.ca_state
ORDER BY
    year_month DESC,
    total_sales_amount DESC
LIMIT 100
