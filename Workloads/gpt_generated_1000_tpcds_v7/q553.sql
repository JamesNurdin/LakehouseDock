SELECT
  p.p_promo_id,
  p.p_promo_name,
  concat(p.p_promo_name, ' - ', w.w_warehouse_name) AS promo_warehouse,
  regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
  COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
  SUM(ws.ws_net_profit) AS total_profit,
  SUM(ws.ws_quantity) AS total_quantity,
  SUM(ws.ws_ext_sales_price) AS total_sales
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2001
  AND regexp_like(p.p_promo_name, 'Clearance')
  AND c.c_first_name LIKE 'A%'
  AND ib.ib_lower_bound >= 50000
  AND ib.ib_upper_bound <= 100000
GROUP BY
  p.p_promo_id,
  p.p_promo_name,
  w.w_warehouse_name,
  regexp_extract(c.c_email_address, '@(.+)$', 1)
HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
