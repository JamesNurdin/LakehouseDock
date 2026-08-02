/* Goal: Summarize web page activity per customer birth month for a filtered set of customers, using a lateral join to web_page, deduplication via UNION, and correlated subqueries for further filtering. */
WITH page_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_day,
        c.c_birth_month,
        COUNT(wp.wp_web_page_sk) AS page_count,
        SUM(wp.wp_char_count) AS total_char_count,
        MAX(wp.wp_image_count) AS max_image_count,
        MIN(wp.wp_max_ad_count) AS min_ad_count
    FROM customer c
    CROSS JOIN LATERAL (
        SELECT
            wp.wp_web_page_sk,
            wp.wp_char_count,
            wp.wp_image_count,
            wp.wp_max_ad_count,
            wp.wp_rec_start_date
        FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_rec_start_date >= DATE '1999-01-01'
          AND wp.wp_image_count >= 2
    ) wp
    WHERE c.c_current_cdemo_sk IN (965059, 1763203, 290962)
      AND c.c_birth_day = 7
      AND c.c_birth_month IN (1, 5, 12)
    GROUP BY c.c_customer_sk, c.c_birth_day, c.c_birth_month
),

union_data AS (
    SELECT
        pg.c_customer_sk,
        pg.c_birth_month,
        pg.page_count,
        pg.total_char_count
    FROM page_agg pg
    WHERE pg.max_image_count >= 3

    UNION

    SELECT
        pg.c_customer_sk,
        pg.c_birth_month,
        pg.page_count,
        pg.total_char_count
    FROM page_agg pg
    WHERE pg.min_ad_count = 0
),

final_stats AS (
    SELECT
        ud.c_birth_month,
        COUNT(DISTINCT ud.c_customer_sk) AS distinct_customers,
        SUM(ud.page_count) AS total_pages,
        AVG(ud.total_char_count) AS avg_char_count,
        MIN(ud.page_count) AS min_pages,
        MAX(ud.page_count) AS max_pages,
        (SELECT AVG(page_count) FROM union_data) AS overall_avg_pages
    FROM union_data ud
    WHERE EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = ud.c_customer_sk
          AND wp2.wp_max_ad_count > 3
    )
    GROUP BY ud.c_birth_month
)

SELECT
    fs.c_birth_month,
    fs.distinct_customers,
    fs.total_pages,
    fs.avg_char_count,
    fs.min_pages,
    fs.max_pages,
    fs.overall_avg_pages
FROM final_stats fs
ORDER BY fs.c_birth_month ASC
LIMIT 100
