WITH base AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_closed.d_fy_quarter_seq AS fy_quarter,
        d_closed.d_fy_year AS fy_year,
        wp.wp_image_count,
        wp.wp_link_count,
        wp.wp_char_count,
        d_access.d_date AS access_date
    FROM store s
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_closed.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE s.s_closed_date_sk IS NOT NULL
      AND wp.wp_image_count IS NOT NULL
),
agg AS (
    SELECT
        s_store_name,
        s_city,
        s_state,
        fy_year,
        fy_quarter,
        COUNT(*) AS page_count,
        SUM(wp_image_count) AS total_images,
        SUM(wp_link_count) AS total_links,
        AVG(wp_char_count) AS avg_char_count,
        MAX(access_date) AS latest_access_date
    FROM base
    WHERE wp_image_count > 0
    GROUP BY
        s_store_name,
        s_city,
        s_state,
        fy_year,
        fy_quarter
    HAVING SUM(wp_image_count) > 10
)
SELECT
    s_store_name,
    s_city,
    s_state,
    fy_year,
    fy_quarter,
    page_count,
    total_images,
    total_links,
    avg_char_count,
    latest_access_date,
    RANK() OVER (PARTITION BY fy_year, fy_quarter ORDER BY total_images DESC) AS store_image_rank,
    total_images * 0.01 AS image_tax_estimate
FROM agg
ORDER BY total_images DESC
LIMIT 100
