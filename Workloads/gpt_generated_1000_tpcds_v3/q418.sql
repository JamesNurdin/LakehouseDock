WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain
    FROM customer c
    WHERE regexp_like(c.c_email_address, '^.+@example\\.com$')
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    fc.full_name,
    fc.email_domain,
    s.s_store_name,
    concat(s.s_city, ', ', s.s_state) AS store_location,
    sum(ss.ss_net_paid_inc_tax) AS total_spent,
    count(*) AS purchase_count,
    min(t.t_sub_shift) AS earliest_shift,
    max(t.t_sub_shift) AS latest_shift,
    regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS visited_domain
FROM filtered_customers fc
JOIN store_sales ss ON ss.ss_customer_sk = fc.c_customer_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
LEFT JOIN web_page wp ON wp.wp_customer_sk = fc.c_customer_sk
WHERE t.t_sub_shift LIKE '%evening%'
GROUP BY
    fc.full_name,
    fc.email_domain,
    s.s_store_name,
    concat(s.s_city, ', ', s.s_state),
    regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1)
ORDER BY total_spent DESC
LIMIT 100
