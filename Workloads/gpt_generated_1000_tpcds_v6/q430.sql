WITH store_customer_returns AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        c.c_customer_sk,
        c.c_salutation,
        c.c_first_name,
        c.c_email_address,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '\\.com$')
      AND (c.c_salutation LIKE 'Mr.%' OR c.c_salutation LIKE 'Mrs.%')
      AND c.c_first_name LIKE 'A%'
)
SELECT
    scr.s_store_sk,
    scr.s_store_name,
    scr.s_city,
    COUNT(DISTINCT scr.c_customer_sk) AS num_customers,
    AVG(scr.sr_net_loss) AS avg_net_loss,
    regexp_extract(MIN(scr.c_email_address), '@(.+)$', 1) AS sample_email_domain
FROM store_customer_returns scr
GROUP BY scr.s_store_sk, scr.s_store_name, scr.s_city
HAVING AVG(scr.sr_net_loss) > (
    SELECT AVG(sr2.sr_net_loss)
    FROM store_returns sr2
)
ORDER BY avg_net_loss DESC
LIMIT 10
