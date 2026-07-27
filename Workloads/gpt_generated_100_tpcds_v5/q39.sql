WITH recent_web AS (
    SELECT
        wp_web_page_sk,
        wp_customer_sk,
        wp_char_count,
        wp_image_count,
        wp_rec_end_date,
        wp_url,
        wp_creation_date_sk
    FROM web_page
    WHERE wp_rec_end_date > DATE '2000-01-01'
      AND wp_url LIKE 'http://www.%'
),
agg AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        d.d_year,
        d.d_date,
        COUNT(DISTINCT cp.cp_catalog_page_sk) AS catalog_page_cnt,
        SUM(cp.cp_catalog_page_number) AS total_catalog_numbers,
        AVG(rw.wp_char_count) AS avg_char_count,
        MIN(rw.wp_image_count) AS min_image_count,
        MAX(d.d_week_seq) AS max_week_seq,
        COALESCE(rw.wp_web_page_sk, -1) AS web_page_sk_or_minus1,
        (SELECT COUNT(*) FROM web_page wp_all WHERE wp_all.wp_customer_sk = rw.wp_customer_sk) AS pages_per_customer,
        rw.wp_customer_sk
    FROM catalog_page cp
    JOIN date_dim d
        ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN recent_web rw
        ON cp.cp_end_date_sk = rw.wp_creation_date_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_catalog_number BETWEEN 5 AND 20
      AND d.d_dow = 2
      AND d.d_week_seq >= 4
      AND d.d_following_holiday = 'N'
      AND EXISTS (
            SELECT 1 FROM web_page wp3
            WHERE wp3.wp_customer_sk = rw.wp_customer_sk
              AND wp3.wp_char_count > 1500
          )
    GROUP BY cp.cp_department, cp.cp_type, d.d_year, d.d_date, rw.wp_web_page_sk, rw.wp_customer_sk
)
SELECT
    cp_department,
    cp_type,
    d_year,
    catalog_page_cnt,
    total_catalog_numbers,
    avg_char_count,
    min_image_count,
    max_week_seq,
    web_page_sk_or_minus1,
    pages_per_customer,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY d_date DESC) AS dept_page_rank
FROM agg
ORDER BY total_catalog_numbers DESC
LIMIT 100
