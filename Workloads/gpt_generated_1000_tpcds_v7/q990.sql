WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_sold_time_sk,
        ss.ss_net_paid,
        ss.ss_quantity,
        s.s_city,
        s.s_state,
        s.s_zip,
        t.t_hour
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE regexp_like(c.c_email_address, '^.*@example\\.com$')
      AND s.s_city LIKE 'San%'
)
SELECT
    s.s_city || '-' || s.s_state AS city_state,
    substring(s.s_zip, 1, 5) AS zip_prefix,
    t.t_hour AS hour_of_day,
    sum(ss.ss_net_paid) AS total_net_paid,
    avg(ss.ss_quantity) AS avg_quantity,
    count(*) AS transaction_cnt,
    count(distinct regexp_extract(c.c_email_address, '([^@]+)@', 1)) AS distinct_email_users
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
WHERE regexp_like(c.c_email_address, '^.*@example\\.com$')
  AND s.s_city LIKE 'San%'
GROUP BY
    s.s_city || '-' || s.s_state,
    substring(s.s_zip, 1, 5),
    t.t_hour
ORDER BY total_net_paid DESC
LIMIT 100
