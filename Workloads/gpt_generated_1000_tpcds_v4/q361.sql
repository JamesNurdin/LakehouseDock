WITH wp_agg AS (
    SELECT
        wp_customer_sk,
        COUNT(*) AS page_cnt,
        SUM(wp_image_count) AS total_images,
        MAX(wp_char_count) AS max_char_count
    FROM web_page
    WHERE wp_type = 'content'
      AND wp_image_count >= 2
    GROUP BY wp_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_month,
    wp_agg.page_cnt,
    wp_agg.total_images,
    CASE
        WHEN wp_agg.total_images > 100 THEN 'High'
        WHEN wp_agg.total_images > 50 THEN 'Medium'
        ELSE 'Low'
    END AS image_intensity,
    RANK() OVER (ORDER BY wp_agg.total_images DESC) AS image_rank,
    ROW_NUMBER() OVER (
        PARTITION BY CASE WHEN c.c_birth_month IN (12, 1, 2) THEN 'Winter' ELSE 'Other' END
        ORDER BY wp_agg.page_cnt DESC
    ) AS rn_by_season
FROM customer c
JOIN wp_agg ON wp_agg.wp_customer_sk = c.c_customer_sk
WHERE c.c_current_addr_sk IN (4628047, 4417012, 338968)
  AND c.c_birth_month BETWEEN 3 AND 8
  AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_url LIKE 'http://www.%'
          AND wp.wp_link_count > 5
    )
ORDER BY wp_agg.total_images DESC, c.c_customer_id
LIMIT 100
