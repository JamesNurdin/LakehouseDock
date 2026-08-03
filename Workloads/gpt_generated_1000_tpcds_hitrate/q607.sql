WITH max_demo AS (
    SELECT MAX(c_current_hdemo_sk) AS max_hd
    FROM customer
    WHERE c_birth_country = 'ETHIOPIA'
),
filtered AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_country,
        c.c_current_hdemo_sk,
        wp.wp_web_page_id,
        wp.wp_url,
        wp.wp_type,
        wp.wp_image_count,
        wp.wp_rec_start_date,
        ROW_NUMBER() OVER (PARTITION BY c.c_birth_country ORDER BY wp.wp_image_count DESC) AS rn_per_country,
        RANK() OVER (ORDER BY wp.wp_image_count DESC) AS global_image_rank
    FROM
        customer c
        JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_country IN ('ETHIOPIA', 'AZERBAIJAN', 'BOTSWANA')
        AND c.c_current_hdemo_sk > 4700
        AND c.c_preferred_cust_flag = 'Y'
        AND wp.wp_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2002-12-31'
        AND wp.wp_image_count BETWEEN 2 AND 7
        AND wp.wp_type = 'CONTENT'
        AND wp.wp_autogen_flag = 'N'
        AND c.c_current_hdemo_sk = (SELECT max_hd FROM max_demo)
        AND EXISTS (
            SELECT 1
            FROM web_page wp2
            WHERE wp2.wp_customer_sk = c.c_customer_sk
              AND wp2.wp_image_count > wp.wp_image_count
        )
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    c_birth_country,
    c_current_hdemo_sk,
    wp_web_page_id,
    wp_url,
    wp_type,
    wp_image_count,
    wp_rec_start_date,
    rn_per_country,
    global_image_rank
FROM filtered
WHERE rn_per_country <= 5
ORDER BY c_birth_country, global_image_rank
OFFSET 0
LIMIT 100
