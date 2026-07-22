WITH store_profit_avg AS (
    SELECT avg(store_profit) AS avg_profit
    FROM (
        SELECT ss2.ss_store_sk, sum(ss2.ss_net_profit) AS store_profit
        FROM store_sales ss2
        GROUP BY ss2.ss_store_sk
    ) sp
)
SELECT
    s.s_store_id,
    s.s_store_name,
    concat(s.s_city, ', ', s.s_state) AS store_location,
    sum(ss.ss_net_profit) AS total_net_profit,
    count(DISTINCT c.c_customer_id) AS unique_customers,
    array_agg(DISTINCT regexp_extract(c.c_email_address, '@(.+)$')) AS email_domains
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
WHERE
    p.p_promo_name IS NOT NULL
    AND regexp_like(p.p_promo_name, '(?i)discount')
    AND c.c_preferred_cust_flag = 'Y'
    AND c.c_first_name LIKE 'A%'
    AND regexp_like(c.c_email_address, '^.+@example[.]com$')
    AND EXISTS (
        SELECT 1
        FROM store_returns sr
        JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        WHERE sr.sr_store_sk = s.s_store_sk
          AND sr.sr_ticket_number = ss.ss_ticket_number
          AND regexp_like(r.r_reason_desc, '(?i)damaged')
    )
GROUP BY
    s.s_store_id,
    s.s_store_name,
    concat(s.s_city, ', ', s.s_state)
HAVING sum(ss.ss_net_profit) > (SELECT avg_profit FROM store_profit_avg)
ORDER BY total_net_profit DESC
LIMIT 10
