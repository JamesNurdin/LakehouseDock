WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_ext_sales_price,
        ws.ws_bill_addr_sk,
        ws.ws_sold_date_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt
    FROM web_returns wr
)
SELECT
    i.i_category,
    ca.ca_state,
    SUM(s.ws_quantity) AS total_quantity_sold,
    SUM(s.ws_net_paid) AS total_revenue,
    SUM(s.ws_net_profit) AS total_profit,
    COALESCE(SUM(r.wr_return_quantity), 0) AS total_return_quantity,
    COALESCE(SUM(r.wr_return_amt), 0) AS total_return_amount,
    COALESCE(SUM(r.wr_return_quantity), 0) / NULLIF(SUM(s.ws_quantity), 0) AS return_rate,
    SUM(s.ws_ext_discount_amt) / NULLIF(SUM(s.ws_ext_sales_price), 0) AS avg_discount_rate
FROM sales s
JOIN item i ON s.ws_item_sk = i.i_item_sk
JOIN customer_address ca ON s.ws_bill_addr_sk = ca.ca_address_sk
LEFT JOIN returns r ON s.ws_order_number = r.wr_order_number
                     AND s.ws_item_sk = r.wr_item_sk
GROUP BY i.i_category, ca.ca_state
ORDER BY total_revenue DESC
LIMIT 10
