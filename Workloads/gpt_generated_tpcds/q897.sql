SELECT
    wsit.web_name,
    d.d_year,
    d.d_month_seq,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_promo_sk) AS distinct_promotions,
    AVG(ws.ws_quantity) AS avg_quantity,
    max_by(wp.wp_type, ws.ws_ext_sales_price) AS top_page_type
FROM web_sales ws
JOIN date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site wsit
  ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
  AND ws.ws_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
WHERE d.d_year = 2002
GROUP BY wsit.web_name, d.d_year, d.d_month_seq
ORDER BY wsit.web_name, d.d_month_seq
