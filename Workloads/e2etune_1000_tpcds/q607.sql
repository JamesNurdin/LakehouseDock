SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    cp.cp_department,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    AVG(cd.cd_purchase_estimate) AS avg_estimated_purchase,
    SUM(CASE WHEN cp.cp_type = 'monthly' THEN 1 ELSE 0 END) AS monthly_pages,
    SUM(CASE WHEN cp.cp_type = 'quarterly' THEN 1 ELSE 0 END) AS quarterly_pages
FROM
    customer c
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp
        ON c.c_birth_month = cp.cp_catalog_page_number
WHERE
    c.c_birth_year BETWEEN 1965 AND 1995
    AND cd.cd_credit_rating IN ('A', 'B', 'C')
    AND cp.cp_start_date_sk >= 2450800
GROUP BY
    cd.cd_gender,
    cd.cd_marital_status,
    cp.cp_department
HAVING
    COUNT(DISTINCT c.c_customer_sk) > 20
ORDER BY
    num_customers DESC
LIMIT 100
