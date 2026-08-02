WITH filtered_customers AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        REGEXP_EXTRACT(c.c_email_address, '@([^.]*)') AS email_domain,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_dep_count,
        cd.cd_dep_college_count
    FROM
        tpcds.customer c
        JOIN tpcds.customer_demographics cd
            ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        REGEXP_LIKE(c.c_email_address, '@example\\.com$')
        AND c.c_login LIKE 'A%'
        AND cd.cd_dep_count >= 2
        AND cd.cd_education_status LIKE '%Degree%'
)
SELECT
    cd_education_status,
    cd_gender,
    COUNT(*) AS customer_count,
    AVG(cd_dep_count) AS avg_dep_count,
    MAX(cd_dep_count) AS max_dep_count,
    MIN(cd_dep_count) AS min_dep_count,
    (SELECT AVG(cd_dep_count) FROM tpcds.customer_demographics) AS overall_avg_dep_count
FROM
    filtered_customers
GROUP BY
    cd_education_status,
    cd_gender
HAVING
    COUNT(*) >= 5
ORDER BY
    customer_count DESC,
    cd_education_status
OFFSET 0 LIMIT 100
