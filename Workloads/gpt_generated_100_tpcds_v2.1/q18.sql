SELECT
    c.c_customer_id,
    concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
    regexp_extract(c.c_email_address, '([^@]+)@(.+)$', 2) AS email_domain,
    p.p_promo_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_transactions,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity
FROM store_sales ss
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
WHERE
    regexp_like(p.p_promo_name, '(?i)discount')
    AND regexp_extract(c.c_email_address, '([^@]+)@(.+)$', 2) LIKE '%.com'
    AND c.c_last_name LIKE 'S%'
    AND c.c_customer_sk IN (SELECT DISTINCT sr.sr_customer_sk FROM store_returns sr)
GROUP BY
    c.c_customer_id,
    concat(c.c_first_name, ' ', c.c_last_name),
    regexp_extract(c.c_email_address, '([^@]+)@(.+)$', 2),
    p.p_promo_name
ORDER BY total_net_profit DESC
LIMIT 100
