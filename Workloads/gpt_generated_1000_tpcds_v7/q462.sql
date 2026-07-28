WITH filtered AS (
    SELECT
        d.d_date,
        d.d_day_name,
        d.d_year,
        wp.wp_web_page_id,
        wp.wp_url,
        wp.wp_type,
        wp.wp_link_count,
        wp.wp_image_count,
        wp.wp_rec_start_date,
        ROW_NUMBER() OVER (PARTITION BY d.d_date ORDER BY wp.wp_link_count DESC) AS link_rank,
        CASE
            WHEN wp.wp_link_count >= 20 THEN 'HIGH'
            WHEN wp.wp_link_count >= 10 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS link_category
    FROM date_dim d
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND d.d_month_seq BETWEEN 2400 AND 2420
      AND wp.wp_type IN ('Home', 'Product')
      AND wp.wp_link_count > 10
      AND wp.wp_image_count BETWEEN 5 AND 30
      AND wp.wp_rec_start_date >= DATE '1999-01-01'
)
SELECT
    d_date,
    d_day_name,
    d_year,
    wp_web_page_id,
    wp_url,
    wp_type,
    wp_link_count,
    wp_image_count,
    wp_rec_start_date,
    link_rank,
    link_category
FROM filtered
WHERE link_rank <= 5
ORDER BY d_date DESC, link_rank
LIMIT 100
