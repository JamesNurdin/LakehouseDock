WITH filtered_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_store_sk,
        sr.sr_customer_sk,
        sr.sr_net_loss,
        r.r_reason_desc,
        c.c_email_address,
        s.s_store_name,
        s.s_city
    FROM (SELECT * FROM store_returns TABLESAMPLE BERNOULLI (10)) AS sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE REGEXP_LIKE(r.r_reason_desc, '(?i)damage|defect|broken')
      AND c.c_email_address LIKE '%@%.%'
      AND c.c_email_address NOT LIKE '%@test%'
      AND s.s_store_name LIKE 'A%'
),
aggregated AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        REGEXP_EXTRACT(c.c_email_address, '@([A-Za-z0-9.-]+)$', 1) AS email_domain,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
        SUM(fr.sr_net_loss) AS total_net_loss
    FROM filtered_returns fr
    JOIN store s ON fr.sr_store_sk = s.s_store_sk
    JOIN customer c ON fr.sr_customer_sk = c.c_customer_sk
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        REGEXP_EXTRACT(c.c_email_address, '@([A-Za-z0-9.-]+)$', 1)
)
SELECT DISTINCT
    s_store_name,
    CONCAT(s_store_name, ' - ', s_city) AS full_store_desc,
    email_domain,
    distinct_customers,
    total_net_loss,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank,
    SUM(total_net_loss) OVER (
        PARTITION BY s_store_sk
        ORDER BY total_net_loss DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_loss
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
