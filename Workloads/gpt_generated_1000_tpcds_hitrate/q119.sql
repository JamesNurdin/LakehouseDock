SELECT
    s.s_store_name,
    d.d_year,
    CASE WHEN s.s_number_employees > 250 THEN 'Large' ELSE 'Small' END AS store_size,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages
FROM
    store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
WHERE
    REGEXP_LIKE(wp.wp_url, 'promo')
    AND wp.wp_type LIKE 'A%'
    AND SUBSTRING(s.s_store_name, 1, 3) = 'The'
GROUP BY
    s.s_store_name,
    d.d_year,
    CASE WHEN s.s_number_employees > 250 THEN 'Large' ELSE 'Small' END
ORDER BY
    total_net_paid DESC
LIMIT 100
