WITH creation_stats AS (
    SELECT
        'creation' AS source,
        wp.wp_type AS page_type,
        COUNT(*) AS page_count,
        AVG(wp.wp_image_count) AS avg_image_count,
        SUM(wp.wp_max_ad_count) AS total_ad_count,
        CASE WHEN SUM(wp.wp_max_ad_count) > 5 THEN 'High' ELSE 'Low' END AS ad_intensity,
        (SELECT MAX(wp2.wp_image_count)
         FROM web_page wp2
         WHERE wp2.wp_type = wp.wp_type) AS max_image_count_for_type
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND EXISTS (
          SELECT 1
          FROM web_page wp3
          WHERE wp3.wp_type = wp.wp_type
            AND wp3.wp_autogen_flag = 'Y'
            AND wp3.wp_creation_date_sk = wp.wp_creation_date_sk
      )
    GROUP BY wp.wp_type
),
access_stats AS (
    SELECT
        'access' AS source,
        wp.wp_type AS page_type,
        COUNT(*) AS page_count,
        AVG(wp.wp_image_count) AS avg_image_count,
        SUM(wp.wp_max_ad_count) AS total_ad_count,
        CASE WHEN SUM(wp.wp_max_ad_count) > 5 THEN 'High' ELSE 'Low' END AS ad_intensity,
        (SELECT MAX(wp2.wp_image_count)
         FROM web_page wp2
         WHERE wp2.wp_type = wp.wp_type) AS max_image_count_for_type
    FROM web_page wp
    JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND wp.wp_autogen_flag = 'N'
      AND wp.wp_image_count > 2
    GROUP BY wp.wp_type
)
SELECT source,
       page_type,
       page_count,
       avg_image_count,
       total_ad_count,
       ad_intensity,
       max_image_count_for_type
FROM creation_stats
UNION ALL
SELECT source,
       page_type,
       page_count,
       avg_image_count,
       total_ad_count,
       ad_intensity,
       max_image_count_for_type
FROM access_stats
ORDER BY source, page_type
LIMIT 100
