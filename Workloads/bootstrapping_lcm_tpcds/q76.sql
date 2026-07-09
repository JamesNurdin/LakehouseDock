SELECT
    cc.cc_country,
    s.s_state,
    ws_site.web_market_manager,
    d_cc.d_year AS cc_closed_year,
    d_cc.d_month_seq AS cc_closed_month_seq,
    d_cc_open.d_year AS cc_open_year,
    d_cc_open.d_month_seq AS cc_open_month_seq,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month_seq,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(CASE WHEN ws.ws_quantity > 5 THEN ws.ws_net_paid ELSE 0 END) AS high_qty_net_paid,
    SUM(ws.ws_ext_tax) AS total_tax,
    MIN(ws.ws_ext_tax) AS min_tax,
    MAX(ws.ws_ext_tax) AS max_tax
FROM call_center cc
JOIN date_dim d_cc ON cc.cc_closed_date_sk = d_cc.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d_cc.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN date_dim d_site_open ON ws_site.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close ON ws_site.web_close_date_sk = d_site_close.d_date_sk
WHERE d_cc.d_year = 2001
  AND cc.cc_country = 'United States'
  AND s.s_state IS NOT NULL
GROUP BY
    cc.cc_country,
    s.s_state,
    ws_site.web_market_manager,
    d_cc.d_year,
    d_cc.d_month_seq,
    d_cc_open.d_year,
    d_cc_open.d_month_seq,
    d_ship.d_year,
    d_ship.d_month_seq
HAVING SUM(ws.ws_net_paid) > 100000
ORDER BY total_net_paid DESC
LIMIT 100
