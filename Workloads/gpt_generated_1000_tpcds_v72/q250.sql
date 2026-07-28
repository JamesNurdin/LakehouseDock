/* goal: Identify top customers (by catalog sales) who belong to high‑income households, showing their associated store (via any returns), and summarizing their activity across catalog sales, web sales and store returns */
WITH high_income_hd AS (
    SELECT hd.hd_demo_sk
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound > 80000
)
SELECT
    c.c_customer_id,
    s.s_store_name,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(sr.sr_return_amt) AS total_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders
FROM customer c
JOIN customer_demographics cd_cur ON c.c_current_cdemo_sk = cd_cur.cd_demo_sk
JOIN household_demographics hd_cur ON c.c_current_hdemo_sk = hd_cur.hd_demo_sk
JOIN customer_address ca_cur ON c.c_current_addr_sk = ca_cur.ca_address_sk
JOIN high_income_hd hi ON hi.hd_demo_sk = hd_cur.hd_demo_sk
LEFT JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
LEFT JOIN promotion promo_cat ON cs.cs_promo_sk = promo_cat.p_promo_sk
LEFT JOIN warehouse w_cat ON cs.cs_warehouse_sk = w_cat.w_warehouse_sk
LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
LEFT JOIN promotion promo_web ON ws.ws_promo_sk = promo_web.p_promo_sk
LEFT JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
WHERE cd_cur.cd_gender = 'M'
GROUP BY c.c_customer_id, s.s_store_name
ORDER BY total_catalog_sales DESC
LIMIT 100
