WITH filtered AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_login,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
        c.c_first_name || ' ' || c.c_last_name AS full_name
    FROM tpcds.customer c
    JOIN tpcds.customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        regexp_like(c.c_email_address, '^.+@example\\.com$')
        AND c.c_login LIKE 'A%'
        AND regexp_like(c.c_first_name, '^[AEIOUaeiou]')
        AND substring(c.c_last_name, 1, 1) LIKE 'S%'
)
SELECT
    cd.cd_gender AS gender,
    cd.cd_marital_status AS marital_status,
    regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
    COUNT(*) AS customer_cnt,
    AVG(cd.cd_dep_count) AS avg_dep_cnt,
    MIN(c.c_first_name || ' ' || c.c_last_name) AS sample_full_name
FROM filtered f
JOIN tpcds.customer c ON f.c_customer_id = c.c_customer_id
JOIN tpcds.customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY
    cd.cd_gender,
    cd.cd_marital_status,
    regexp_extract(c.c_email_address, '@(.+)$', 1)
ORDER BY customer_cnt DESC
LIMIT 100
