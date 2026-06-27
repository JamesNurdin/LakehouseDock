WITH sales AS (
    SELECT
        d_sold.d_year,
        d_sold.d_month_seq,
        i.i_category,
        i.i_class,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d_sold.d_date >= DATE '2022-01-01'
      AND d_sold.d_date < DATE '2023-01-01'
),
returns AS (
    SELECT
        d_ret.d_year,
        d_ret.d_month_seq,
        i.i_category,
        i.i_class,
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt_inc_tax,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d_ret.d_date >= DATE '2022-01-01'
      AND d_ret.d_date < DATE '2023-01-01'
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.i_class,
    SUM(s.ws_quantity) AS total_quantity_sold,
    SUM(s.ws_ext_sales_price) AS total_sales_amount,
    SUM(s.ws_net_profit) AS total_net_profit,
    COALESCE(SUM(r.wr_return_quantity), 0) AS total_quantity_returned,
    COALESCE(SUM(r.wr_return_amt_inc_tax), 0) AS total_return_amount_inc_tax,
    CASE WHEN SUM(s.ws_quantity) = 0 THEN 0
         ELSE COALESCE(SUM(r.wr_return_quantity), 0) * 100.0 / SUM(s.ws_quantity)
    END AS return_rate_percent,
    AVG(s.ws_ext_discount_amt) AS avg_discount_amount
FROM sales s
LEFT JOIN returns r
    ON s.ws_order_number = r.wr_order_number
   AND s.ws_item_sk = r.wr_item_sk
GROUP BY
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.i_class
ORDER BY
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.i_class
