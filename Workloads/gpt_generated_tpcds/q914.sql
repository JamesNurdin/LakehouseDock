WITH sales_dates AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_ext_sales_price,
        ds.d_year AS sold_year,
        ds.d_month_seq AS sold_month_seq,
        ds.d_date AS sold_date,
        dsh.d_date AS ship_date,
        date_diff('day', ds.d_date, dsh.d_date) AS shipping_delay_days
    FROM web_sales ws
    JOIN date_dim ds
        ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN date_dim dsh
        ON ws.ws_ship_date_sk = dsh.d_date_sk
    WHERE ds.d_year BETWEEN 2020 AND 2022
)
SELECT
    sold_year,
    sold_month_seq,
    sum(ws_net_paid) AS total_net_paid,
    sum(ws_net_profit) AS total_net_profit,
    avg(ws_ext_discount_amt) AS avg_discount_amount,
    avg(shipping_delay_days) AS avg_shipping_delay_days,
    count(distinct ws_order_number) AS distinct_orders,
    sum(sum(ws_net_profit)) OVER (
        PARTITION BY sold_year
        ORDER BY sold_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit_by_year
FROM sales_dates
GROUP BY sold_year, sold_month_seq
ORDER BY sold_year, sold_month_seq
