WITH customer_page_stats AS (
    SELECT
        c.c_customer_sk,
        c.c_salutation,
        c.c_birth_year,
        COUNT(DISTINCT c.c_customer_id) AS distinct_cust_ids,
        SUM(wp.wp_link_count) AS total_links,
        COUNT(DISTINCT wp.wp_url) AS distinct_urls,
        AVG(wp.wp_max_ad_count) AS avg_max_ad
    FROM tpcds.customer c
    JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_salutation IN ('Mr.', 'Ms.', 'Dr.')
      AND c.c_birth_year BETWEEN 1960 AND 1990
      AND c.c_birth_country = 'United States'
      AND c.c_first_sales_date_sk >= 2450000
      AND wp.wp_type = 'Content'
      AND wp.wp_rec_start_date >= DATE '1999-01-01'
      AND wp.wp_max_ad_count > 0
      AND wp.wp_link_count BETWEEN 1 AND 10
    GROUP BY c.c_customer_sk, c.c_salutation, c.c_birth_year
    HAVING SUM(wp.wp_link_count) > 5
),
final_stats AS (
    SELECT
        cps.c_customer_sk,
        cps.c_salutation,
        cps.c_birth_year,
        cps.total_links,
        cps.distinct_urls,
        cps.avg_max_ad,
        (
            SELECT COUNT(*)
            FROM tpcds.web_page wp2
            WHERE wp2.wp_customer_sk = cps.c_customer_sk
              AND wp2.wp_type = 'Home'
        ) AS home_page_count
    FROM customer_page_stats cps
    WHERE cps.distinct_urls > 2
)
SELECT
    fs.c_customer_sk,
    fs.c_salutation,
    fs.c_birth_year,
    fs.total_links,
    fs.distinct_urls,
    fs.avg_max_ad,
    fs.home_page_count,
    COUNT(DISTINCT fs.c_customer_sk) OVER () AS total_customers,
    SUM(fs.total_links) OVER () AS grand_total_links
FROM final_stats fs
WHERE fs.home_page_count >= 1
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_page wp3
        WHERE wp3.wp_customer_sk = fs.c_customer_sk
          AND wp3.wp_char_count > 100
    )
GROUP BY
    fs.c_customer_sk,
    fs.c_salutation,
    fs.c_birth_year,
    fs.total_links,
    fs.distinct_urls,
    fs.avg_max_ad,
    fs.home_page_count
HAVING SUM(fs.total_links) > 10
ORDER BY fs.total_links DESC, fs.c_customer_sk
LIMIT 100
