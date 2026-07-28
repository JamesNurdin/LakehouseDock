WITH filtered AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_salutation,
        w.wp_char_count,
        w.wp_type
    FROM tpcds.customer c
    JOIN tpcds.web_page w
        ON w.wp_customer_sk = c.c_customer_sk
    WHERE c.c_email_address LIKE '%@VFAxlnZEvOx.org'
      AND c.c_salutation IN ('Mrs.', 'Mr.')
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND c.c_first_sales_date_sk BETWEEN 2451900 AND 2452300
      AND w.wp_type = 'Content'
      AND w.wp_char_count > 2500
)
SELECT
    f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    f.c_email_address,
    f.c_salutation,
    COUNT(*) AS page_count,
    SUM(f.wp_char_count) AS total_char_count,
    AVG(f.wp_char_count) AS avg_char_count,
    RANK() OVER (
        PARTITION BY f.c_salutation
        ORDER BY SUM(f.wp_char_count) DESC
    ) AS salutation_rank
FROM filtered f
GROUP BY
    f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    f.c_email_address,
    f.c_salutation
ORDER BY salutation_rank, f.c_customer_id
LIMIT 100
