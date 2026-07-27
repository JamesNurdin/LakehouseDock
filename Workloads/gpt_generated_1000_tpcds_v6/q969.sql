WITH page_counts AS (
    SELECT
        c.c_customer_sk,
        COUNT(*) AS page_cnt
    FROM tpcds.web_page wp
    JOIN tpcds.customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    (
        SELECT cd.cd_gender
        FROM tpcds.customer_demographics cd
        WHERE cd.cd_demo_sk = c.c_current_cdemo_sk
    ) AS gender,
    (
        SELECT cd.cd_education_status
        FROM tpcds.customer_demographics cd
        WHERE cd.cd_demo_sk = c.c_current_cdemo_sk
    ) AS education_status,
    wp.wp_url,
    wp.wp_type,
    wp.wp_char_count,
    CASE WHEN wp.wp_char_count > 5000 THEN 'High' ELSE 'Low' END AS char_category,
    pc.page_cnt AS pages_per_customer,
    ROW_NUMBER() OVER (
        PARTITION BY (
            SELECT cd.cd_gender
            FROM tpcds.customer_demographics cd
            WHERE cd.cd_demo_sk = c.c_current_cdemo_sk
        )
        ORDER BY wp.wp_char_count DESC
    ) AS gender_char_rank,
    RANK() OVER (ORDER BY wp.wp_char_count DESC) AS overall_char_rank
FROM tpcds.customer c
JOIN tpcds.web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN page_counts pc
    ON pc.c_customer_sk = c.c_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM tpcds.customer_demographics cd
    WHERE cd.cd_demo_sk = c.c_current_cdemo_sk
      AND cd.cd_education_status = 'College'
      AND cd.cd_dep_college_count >= 1
)
  AND c.c_birth_month = 7
  AND c.c_preferred_cust_flag = 'Y'
  AND wp.wp_type IN ('welcome', 'ad')
  AND wp.wp_autogen_flag = 'N'
  AND wp.wp_rec_start_date >= DATE '1999-01-01'
  AND wp.wp_rec_start_date <= DATE '2000-12-31'
ORDER BY overall_char_rank
LIMIT 100
