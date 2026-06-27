SELECT
    ws.ws_web_site_sk,
    ws_site.web_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
    COUNT(DISTINCT p.p_promo_sk) AS promo_count
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_start
  ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
  ON p.p_end_date_sk = d_end.d_date_sk
WHERE d_sold.d_date >= d_start.d_date
  AND d_sold.d_date <= d_end.d_date
  AND d_sold.d_year = 2001
GROUP BY
    ws.ws_web_site_sk,
    ws_site.web_name,
    d_sold.d_year,
    d_sold.d_month_seq
ORDER BY total_net_profit DESC
LIMIT 10
