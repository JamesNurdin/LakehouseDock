WITH filtered_customer AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        c_birth_country,
        c_last_review_date
    FROM
        customer
    WHERE
        c_birth_country = 'CYPRUS'
        AND c_last_review_date > 2452300
),
filtered_web_page AS (
    SELECT
        wp_web_page_sk,
        wp_customer_sk,
        wp_char_count,
        wp_autogen_flag,
        wp_rec_start_date
    FROM
        web_page
    WHERE
        wp_autogen_flag = 'N'
        AND wp_char_count > 1000
        AND wp_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'
),
base AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_country,
        COUNT(DISTINCT wp.wp_web_page_sk) AS num_pages,
        SUM(wp.wp_char_count) AS total_char_count,
        AVG(wp.wp_char_count) AS avg_char_count,
        MIN(wp.wp_char_count) AS min_char_count,
        MAX(wp.wp_char_count) AS max_char_count,
        lp.max_char_for_cust
    FROM
        filtered_customer c
    FULL OUTER JOIN
        filtered_web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    CROSS JOIN LATERAL (
        SELECT MAX(wp3.wp_char_count) AS max_char_for_cust
        FROM web_page wp3
        WHERE wp3.wp_customer_sk = c.c_customer_sk
    ) AS lp
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_country,
        lp.max_char_for_cust
)
SELECT
    b.c_customer_id,
    b.c_birth_country,
    b.num_pages,
    b.total_char_count,
    b.avg_char_count,
    b.min_char_count,
    b.max_char_count,
    b.max_char_for_cust,
    ROW_NUMBER() OVER (PARTITION BY b.c_birth_country ORDER BY b.total_char_count DESC) AS rank_by_country,
    (SELECT AVG(wp2.wp_char_count) FROM web_page wp2) AS overall_avg_char_count
FROM
    base b
ORDER BY
    b.total_char_count DESC
LIMIT 100
