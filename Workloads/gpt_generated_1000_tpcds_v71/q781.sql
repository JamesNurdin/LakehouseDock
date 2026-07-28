SELECT
    concat('Promo: ', p.p_promo_name) AS promo_label,
    COUNT(*) AS transaction_count,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales,
    MIN(d.d_year) AS first_year,
    MAX(d.d_year) AS end_year
FROM store_sales ss
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
WHERE regexp_like(p.p_promo_name, '(?i)holiday')
  AND c.c_email_address LIKE '%@gmail.com'
  AND substring(c.c_first_name, 1, 1) = 'A'
GROUP BY concat('Promo: ', p.p_promo_name)
ORDER BY total_sales DESC
LIMIT 100
