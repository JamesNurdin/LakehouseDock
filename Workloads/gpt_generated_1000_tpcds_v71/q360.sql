WITH avg_profit_cte AS (
    SELECT avg(ss_net_profit) AS avg_profit
    FROM tpcds.store_sales
)
SELECT
    c.c_customer_id,
    concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
    regexp_extract(c.c_email_address, '@([A-Za-z0-9.-]+)$', 1) AS email_domain,
    p.p_promo_name,
    sum(ss.ss_net_paid) AS total_paid,
    sum(ss.ss_net_profit) AS total_profit,
    count(*) AS sales_count
FROM tpcds.store_sales ss
JOIN tpcds.customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
WHERE
    regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@.*\\.com$')
    AND p.p_promo_name LIKE '%Summer%'
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    p.p_promo_name
HAVING
    sum(ss.ss_net_profit) > (SELECT avg_profit FROM avg_profit_cte) * 2
ORDER BY total_profit DESC
LIMIT 100
