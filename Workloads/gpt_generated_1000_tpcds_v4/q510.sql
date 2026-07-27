WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
        ca.ca_state,
        hd.hd_buy_potential,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(c.c_email_address, '@example\\.com$')
      AND ca.ca_street_type LIKE 'Avenue%'
      AND hd.hd_buy_potential = '>10000'
)
SELECT
    ca_state,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    SUM(wr_net_loss) AS total_net_loss,
    CONCAT(MIN(c_first_name), ' ', MIN(c_last_name)) AS sample_customer_name,
    ARRAY_AGG(DISTINCT email_domain) AS email_domains
FROM filtered_customers
GROUP BY ca_state
ORDER BY total_net_loss DESC
