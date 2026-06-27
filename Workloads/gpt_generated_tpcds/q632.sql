SELECT
    d_sold.d_year AS year,
    d_sold.d_month_seq AS month_seq,
    i.i_category AS category,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS profit_margin,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(ws.ws_quantity) AS total_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(DATE_DIFF('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_lag_days
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
WHERE d_sold.d_date >= DATE '2001-01-01'
  AND d_sold.d_date < DATE '2002-01-01'
GROUP BY d_sold.d_year, d_sold.d_month_seq, i.i_category
ORDER BY d_sold.d_year, d_sold.d_month_seq, i.i_category
