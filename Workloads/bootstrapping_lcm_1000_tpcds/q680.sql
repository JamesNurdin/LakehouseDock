SELECT
    s.s_store_id,
    s.s_city,
    d_store.d_date AS store_closed_date,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    AVG(p.p_cost) AS avg_promo_cost,
    MIN(p.p_discount_active) AS any_discount_active,
    MAX(d_shipto.d_year) AS latest_shipto_year,
    MIN(d_sales.d_year) AS earliest_sales_year,
    COUNT(DISTINCT p.p_promo_id) AS num_promos,
    SUM(CASE WHEN p.p_channel_email = 'Y' THEN 1 ELSE 0 END) AS email_promos,
    AVG(CAST(ca.ca_gmt_offset AS double)) AS avg_gmt_offset
FROM store s
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_store.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN customer c ON c.c_first_sales_date_sk = d_store.d_date_sk
JOIN date_dim d_shipto ON c.c_first_shipto_date_sk = d_shipto.d_date_sk
JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE s.s_state = 'CA'
GROUP BY s.s_store_id, s.s_city, d_store.d_date
HAVING COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY avg_promo_cost DESC
LIMIT 100
