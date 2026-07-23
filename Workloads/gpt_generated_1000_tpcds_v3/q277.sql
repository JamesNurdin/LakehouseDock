WITH aggregated_returns AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        ca.ca_city,
        ca.ca_state,
        r.r_reason_desc,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damaged|defective')
      AND ca.ca_zip LIKE '57%'
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        ca.ca_city,
        ca.ca_state,
        r.r_reason_desc
),
customer_domain AS (
    SELECT
        ar.*, 
        regexp_extract(ar.c_email_address, '@(.+)$', 1) AS email_domain
    FROM aggregated_returns ar
)
SELECT
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.email_domain,
    cd.ca_city,
    cd.ca_state,
    cd.r_reason_desc,
    cd.total_net_loss,
    (SELECT avg(s.sr_net_loss) FROM store_returns s) AS overall_avg_net_loss,
    CASE
        WHEN cd.total_net_loss > (SELECT avg(s.sr_net_loss) FROM store_returns s) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS net_loss_category,
    row_number() OVER (PARTITION BY cd.email_domain ORDER BY cd.total_net_loss DESC) AS rn_within_domain
FROM customer_domain cd
WHERE cd.total_net_loss > (SELECT avg(s.sr_net_loss) FROM store_returns s)
ORDER BY cd.total_net_loss DESC
LIMIT 100
