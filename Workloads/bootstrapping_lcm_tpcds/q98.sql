SELECT
    d.d_year * 10 + d.d_quarter_seq AS year_quarter_id,
    s.s_division_name,
    w.web_country,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    CASE
        WHEN SUM(ws.ws_ext_sales_price) > 0 THEN SUM(sr.sr_net_loss) / SUM(ws.ws_ext_sales_price)
        ELSE NULL
    END AS return_loss_ratio
FROM date_dim d
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
    AND s.s_closed_date_sk = d.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_ship_date_sk = d.d_date_sk
JOIN web_site w
    ON ws.ws_web_site_sk = w.web_site_sk
    AND w.web_open_date_sk = d.d_date_sk
    AND w.web_close_date_sk = d.d_date_sk
GROUP BY
    d.d_year * 10 + d.d_quarter_seq,
    s.s_division_name,
    w.web_country
HAVING SUM(ws.ws_ext_sales_price) > 0
ORDER BY total_sales DESC
LIMIT 100
