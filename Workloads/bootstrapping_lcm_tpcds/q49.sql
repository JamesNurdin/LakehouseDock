SELECT
    d_sold.d_year,
    d_sold.d_quarter_name,
    s.s_market_desc,
    i.i_category,
    CASE 
        WHEN ws.ws_ext_sales_price > 0 
        THEN CAST(FLOOR(ws.ws_net_profit / ws.ws_ext_sales_price * 100) AS integer)
        ELSE NULL
    END AS profit_pct,
    CASE 
        WHEN date_diff('day', d_sold.d_date, d_ship.d_date) <= 0 THEN 'same_day'
        WHEN date_diff('day', d_sold.d_date, d_ship.d_date) BETWEEN 1 AND 2 THEN '1-2_days'
        ELSE '3+_days'
    END AS shipping_delay_bucket,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(CASE WHEN wr.wr_return_amt IS NOT NULL THEN 1 ELSE 0 END) AS return_count
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    d_sold.d_year,
    d_sold.d_quarter_name,
    s.s_market_desc,
    i.i_category,
    CASE 
        WHEN ws.ws_ext_sales_price > 0 
        THEN CAST(FLOOR(ws.ws_net_profit / ws.ws_ext_sales_price * 100) AS integer)
        ELSE NULL
    END,
    CASE 
        WHEN date_diff('day', d_sold.d_date, d_ship.d_date) <= 0 THEN 'same_day'
        WHEN date_diff('day', d_sold.d_date, d_ship.d_date) BETWEEN 1 AND 2 THEN '1-2_days'
        ELSE '3+_days'
    END
HAVING SUM(ws.ws_ext_sales_price) > 5000
ORDER BY total_sales DESC
LIMIT 50
