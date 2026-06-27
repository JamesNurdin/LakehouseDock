WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_bill_cdemo_sk
    FROM web_sales ws
),
returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS return_qty,
        SUM(wr.wr_return_amt) AS return_amt
    FROM web_returns wr
    GROUP BY wr.wr_order_number, wr.wr_item_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    sm.sm_type,
    cd.cd_gender,
    SUM(s.ws_ext_sales_price) AS total_sales,
    SUM(s.ws_net_profit) AS total_profit,
    COUNT(DISTINCT s.ws_order_number) AS total_orders,
    COUNT(DISTINCT CASE WHEN r.return_qty IS NOT NULL THEN s.ws_order_number END) AS orders_with_returns,
    SUM(COALESCE(r.return_qty, 0)) AS total_return_quantity,
    SUM(COALESCE(r.return_amt, 0)) AS total_return_amount,
    (COUNT(DISTINCT CASE WHEN r.return_qty IS NOT NULL THEN s.ws_order_number END) * 100.0 / NULLIF(COUNT(DISTINCT s.ws_order_number), 0)) AS return_rate_percent
FROM sales s
LEFT JOIN returns r
    ON s.ws_order_number = r.wr_order_number
   AND s.ws_item_sk = r.wr_item_sk
JOIN date_dim d
    ON s.ws_sold_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
    ON s.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE d.d_year = 2020
GROUP BY
    d.d_year,
    d.d_month_seq,
    sm.sm_type,
    cd.cd_gender
ORDER BY
    d.d_year,
    d.d_month_seq,
    sm.sm_type,
    cd.cd_gender
