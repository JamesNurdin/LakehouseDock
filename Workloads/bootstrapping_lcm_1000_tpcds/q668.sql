SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month_seq,
    s.s_store_name,
    ws.web_name,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    COUNT(DISTINCT cs.cs_order_number) AS num_sales,
    AVG(cs.cs_quantity) AS avg_quantity_sold,
    SUM(cs.cs_ext_sales_price) - SUM(cr.cr_return_amount) AS net_sales_minus_returns
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_web_close
    ON ws.web_close_date_sk = d_web_close.d_date_sk
WHERE d_ret.d_year = 2001
  AND s.s_state = 'CA'
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    ws.web_name
ORDER BY total_net_loss DESC
LIMIT 100
