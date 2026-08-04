WITH filtered AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_customer_sk,
        wp.wp_url,
        wp.wp_type,
        wp.wp_max_ad_count,
        wp.wp_rec_start_date,
        c.c_customer_id,
        c.c_salutation,
        c.c_last_review_date
    FROM web_page wp
    JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE wp.wp_autogen_flag = 'Y'
      AND wp.wp_max_ad_count >= 1
      AND wp.wp_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
      AND c.c_last_review_date > 2452500
)
SELECT
    f.c_customer_id,
    f.c_salutation,
    f.c_last_review_date,
    f.wp_url,
    f.wp_type,
    CASE
        WHEN f.wp_max_ad_count = 0 THEN 'NoAds'
        WHEN f.wp_max_ad_count BETWEEN 1 AND 2 THEN 'FewAds'
        ELSE 'ManyAds'
    END AS ad_category,
    (
        SELECT COUNT(*)
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = f.wp_customer_sk
          AND wp2.wp_autogen_flag = 'Y'
    ) AS total_autogen_pages,
    RANK() OVER (PARTITION BY f.c_salutation ORDER BY f.c_last_review_date DESC) AS salutation_rev_review_rank,
    ROW_NUMBER() OVER (ORDER BY f.c_last_review_date DESC, f.wp_web_page_sk) AS overall_row_num
FROM filtered f
ORDER BY f.c_last_review_date DESC, f.c_customer_id
LIMIT 100
