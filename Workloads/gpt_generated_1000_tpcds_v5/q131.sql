SELECT
    s.s_city,
    p.p_promo_name,
    d.d_year,
    cp.cp_department,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ss.ss_quantity) AS total_store_quantity,
    SUM(cs.cs_quantity) AS total_catalog_quantity,
    AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_ticket_count
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN catalog_sales cs
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN inventory i
  ON i.inv_date_sk = d.d_date_sk
JOIN web_site w
  ON w.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND s.s_city = 'Lakeside'
  AND p.p_discount_active = 'Y'
  AND cp.cp_type = 'C'
  AND i.inv_quantity_on_hand > 100
GROUP BY s.s_city, p.p_promo_name, d.d_year, cp.cp_department
ORDER BY total_store_sales DESC
LIMIT 100
