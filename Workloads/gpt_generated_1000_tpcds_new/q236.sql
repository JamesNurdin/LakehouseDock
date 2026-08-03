WITH first_segment AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        CASE WHEN wp.wp_link_count > 15 THEN 'High' ELSE 'Low' END AS link_level,
        lc.total_links
    FROM tpcds.customer c
    JOIN tpcds.web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS total_links
        FROM tpcds.web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
    ) lc
    WHERE wp.wp_autogen_flag = 'N'
      AND c.c_birth_year BETWEEN 1960 AND 1980
      AND c.c_birth_year > (
            SELECT MIN(c2.c_birth_year)
            FROM tpcds.customer c2
            WHERE c2.c_birth_country = 'USA'
        )
      AND EXISTS (
            SELECT 1
            FROM tpcds.web_page wp3
            WHERE wp3.wp_customer_sk = c.c_customer_sk
              AND wp3.wp_type = 'article'
        )
),
second_segment AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        CASE WHEN wp.wp_link_count > 10 THEN 'Medium' ELSE 'Low' END AS link_level,
        lc.total_links
    FROM tpcds.customer c
    JOIN tpcds.web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS total_links
        FROM tpcds.web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
    ) lc
    WHERE wp.wp_autogen_flag = 'Y'
      AND c.c_birth_year > 1970
      AND c.c_birth_year < (
            SELECT MAX(c2.c_birth_year)
            FROM tpcds.customer c2
            WHERE c2.c_birth_country = 'CANADA'
        )
      AND EXISTS (
            SELECT 1
            FROM tpcds.web_page wp3
            WHERE wp3.wp_customer_sk = c.c_customer_sk
              AND wp3.wp_url LIKE 'http://www.foo.com%'
        )
)
SELECT * FROM first_segment
UNION ALL
SELECT * FROM second_segment
ORDER BY c_birth_year DESC, c_customer_id ASC
LIMIT 100
