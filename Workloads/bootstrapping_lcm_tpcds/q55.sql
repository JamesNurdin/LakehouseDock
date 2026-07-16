SELECT
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month_seq,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month_seq,
    cc.cc_market_manager,
    cc.cc_tax_percentage,
    st.s_store_name,
    st.s_city,
    st.s_state,
    ws_site.web_name,
    ws_site.web_city,
    d_cc_open.d_date AS cc_open_date,
    d_cc_closed.d_date AS cc_closed_date,
    d_web_open.d_date AS web_open_date,
    d_web_close.d_date AS web_close_date,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(ws.ws_quantity) AS avg_quantity,
    MIN(d_sold.d_date) AS first_sale_date,
    MAX(d_ship.d_date) AS last_ship_date
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN date_dim d_web_open
    ON ws_site.web_open_date_sk = d_web_open.d_date_sk
JOIN date_dim d_web_close
    ON ws_site.web_close_date_sk = d_web_close.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN store st
    ON st.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_store_closed
    ON st.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2005
  AND ws.ws_net_profit > 0
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_year,
    d_ship.d_month_seq,
    cc.cc_market_manager,
    cc.cc_tax_percentage,
    st.s_store_name,
    st.s_city,
    st.s_state,
    ws_site.web_name,
    ws_site.web_city,
    d_cc_open.d_date,
    d_cc_closed.d_date,
    d_web_open.d_date,
    d_web_close.d_date
ORDER BY total_net_profit DESC
LIMIT 100
