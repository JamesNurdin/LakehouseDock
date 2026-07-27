WITH filtered AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        regexp_extract(c.c_email_address, '@(.+)$', 1)                AS email_domain,
        substr(regexp_extract(c.c_email_address, '@(.+)$', 1), 1, 5) AS domain_prefix,
        c.c_first_name || ' ' || c.c_last_name                     AS full_name,
        CASE WHEN ss.ss_net_profit >= 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
    FROM tpcds.store_sales ss
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(c.c_first_name, '[AEIOUaeiou]')
      AND c.c_email_address LIKE '%@example.com'
      AND hd.hd_buy_potential IS NOT NULL
)
SELECT
    hd_buy_potential,
    hd_dep_count,
    COUNT(DISTINCT ss_customer_sk)                     AS distinct_customers,
    SUM(ss_net_paid)                                   AS total_net_paid,
    AVG(ss_net_profit)                                 AS avg_net_profit,
    CASE
        WHEN SUM(ss_net_profit) > 0 THEN 'POSITIVE'
        ELSE 'NEGATIVE_OR_ZERO'
    END                                                AS profit_status
FROM filtered
GROUP BY hd_buy_potential, hd_dep_count
HAVING SUM(ss_net_paid) > 1000
ORDER BY total_net_paid DESC
