WITH cust_demo AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_salutation,
        c.c_birth_year,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_dep_college_count
    FROM customer c
    LEFT JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_salutation IN ('Mrs.', 'Mr.', 'Dr.')
      AND c.c_birth_year BETWEEN 1950 AND 2000
      AND cd.cd_purchase_estimate > 3000
      AND cd.cd_education_status = 'Advanced Degree'
)
SELECT
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.c_salutation,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    wp.wp_url,
    wp.wp_char_count,
    COALESCE(wp.wp_autogen_flag, 'N') AS autogen_flag,
    RANK() OVER (PARTITION BY cd.cd_education_status ORDER BY cd.cd_purchase_estimate DESC) AS edu_rank,
    ROW_NUMBER() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS overall_seq,
    CASE WHEN EXISTS (
            SELECT 1 FROM web_page wp2
            WHERE wp2.wp_customer_sk = cd.c_customer_sk
              AND wp2.wp_type = 'product'
        ) THEN 1 ELSE 0 END AS has_product_page,
    (SELECT MAX(cd2.cd_purchase_estimate) FROM customer_demographics cd2) AS max_estimate_overall
FROM cust_demo cd
LEFT JOIN web_page wp
    ON wp.wp_customer_sk = cd.c_customer_sk
WHERE (wp.wp_autogen_flag = 'N' OR wp.wp_autogen_flag IS NULL)
  AND (wp.wp_char_count BETWEEN 1000 AND 6000 OR wp.wp_char_count IS NULL)
ORDER BY edu_rank ASC, cd.cd_purchase_estimate DESC
LIMIT 100
