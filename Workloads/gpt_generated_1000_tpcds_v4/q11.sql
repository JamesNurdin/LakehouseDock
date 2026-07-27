WITH sales_filtered AS (
    SELECT
        ss.ss_net_paid,
        s.s_market_manager,
        c.c_email_address,
        i.i_category,
        regexp_extract(c.c_email_address, '@([^.]*)') AS email_domain
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(c.c_email_address, '\\.org$')
      AND s.s_market_manager LIKE '%Nichols%'
)
SELECT
    s_market_manager,
    email_domain,
    i_category,
    COUNT(*) AS num_transactions,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(ss_net_paid) AS avg_net_paid,
    concat(s_market_manager, ':', email_domain) AS manager_domain_tag
FROM sales_filtered
GROUP BY s_market_manager, email_domain, i_category
ORDER BY total_net_paid DESC
LIMIT 10
