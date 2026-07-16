SELECT
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_quarter_name,
    CASE WHEN d_sold.d_month_seq % 2 = 0 THEN 'Even' ELSE 'Odd' END AS month_parity,
    CASE WHEN s.s_closed_date_sk IS NOT NULL THEN 1 ELSE 0 END AS is_closed_store,
    COALESCE(d_closed.d_year, 0) AS closed_year,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(wr.wr_return_amt) AS net_profit_after_returns,
    SUM(ss.ss_ext_sales_price) - SUM(wr.wr_return_amt) AS net_sales_minus_returns,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) > 0
        THEN (SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(wr.wr_return_amt))
             / (SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price))
        ELSE NULL
    END AS profit_margin,
    SUM(CASE WHEN d_sold.d_weekend = 'Y' THEN ss.ss_ext_sales_price ELSE 0 END) AS weekend_store_sales,
    SUM(CASE WHEN d_sold.d_weekend = 'N' THEN ws.ws_ext_sales_price ELSE 0 END) AS weekday_web_sales
FROM store s
JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sold.d_date_sk
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_quarter_name,
    CASE WHEN d_sold.d_month_seq % 2 = 0 THEN 'Even' ELSE 'Odd' END,
    CASE WHEN s.s_closed_date_sk IS NOT NULL THEN 1 ELSE 0 END,
    COALESCE(d_closed.d_year, 0)
HAVING SUM(ss.ss_ext_sales_price) > 5000
ORDER BY total_store_sales DESC
LIMIT 100
