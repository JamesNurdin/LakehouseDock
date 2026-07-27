WITH customer_page_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages,
        SUM(wp.wp_image_count) AS total_images,
        ROW_NUMBER() OVER (PARTITION BY c.c_birth_year ORDER BY SUM(wp.wp_image_count) DESC) AS rn_year
    FROM
        tpcds.customer c
        JOIN tpcds.web_page wp
            ON wp.wp_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1940 AND 1990
        AND wp.wp_image_count >= 2
        AND wp.wp_rec_start_date >= DATE '2000-01-01'
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year
)
SELECT
    DISTINCT ca.c_customer_id,
    ca.c_first_name,
    ca.c_last_name,
    ca.c_birth_year,
    ca.distinct_pages,
    ca.total_images,
    RANK() OVER (PARTITION BY ca.c_birth_year ORDER BY ca.total_images DESC) AS birth_year_image_rank
FROM
    customer_page_agg ca
WHERE
    ca.rn_year <= 5
ORDER BY
    ca.total_images DESC
LIMIT 100
