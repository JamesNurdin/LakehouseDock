WITH sr_filtered AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_customer_sk,
        sr.sr_net_loss,
        sr.sr_return_amt,
        sr.sr_return_quantity
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
),
joined AS (
    SELECT
        s.s_store_name,
        s.s_store_id,
        c.c_email_address,
        ca.ca_city,
        ca.ca_zip,
        sr_filtered.sr_net_loss,
        sr_filtered.sr_return_amt,
        sr_filtered.sr_return_quantity,
        regexp_extract(c.c_email_address, '@(.*)$', 1) AS email_domain,
        substr(ca.ca_zip, 1, 5) AS zip_prefix
    FROM sr_filtered
    JOIN store s ON sr_filtered.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr_filtered.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE regexp_like(s.s_store_name, 'Mart')
      AND ca.ca_city LIKE 'San%'
      AND regexp_like(c.c_email_address, '@gmail\\.com$')
)
SELECT
    s_store_name,
    s_store_id,
    email_domain,
    zip_prefix,
    COUNT(*) AS returns_cnt,
    SUM(sr_net_loss) AS total_net_loss,
    AVG(sr_return_amt) AS avg_return_amount
FROM joined
GROUP BY s_store_name, s_store_id, email_domain, zip_prefix
ORDER BY total_net_loss DESC
LIMIT 100
