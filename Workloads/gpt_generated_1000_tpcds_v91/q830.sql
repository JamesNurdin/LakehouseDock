WITH agg_stats AS (
    SELECT
        wp.wp_type,
        cd.d_year,
        COUNT(*) AS page_cnt,
        SUM(wp.wp_image_count) AS total_images,
        AVG(wp.wp_image_count) AS avg_images
    FROM web_page wp
    JOIN date_dim cd
        ON wp.wp_creation_date_sk = cd.d_date_sk
    WHERE cd.d_moy IN (1, 5, 9)                     -- filter 1: specific months
      AND cd.d_following_holiday = 'N'             -- filter 2: non‑holiday days
      AND wp.wp_image_count > 3                   -- filter 3: pages with >3 images
    GROUP BY GROUPING SETS (
        (wp.wp_type, cd.d_year),   -- detail rows (type + year)
        (wp.wp_type),              -- subtotal per type
        (cd.d_year),               -- subtotal per year
        ()                         -- grand total
    )
    HAVING COUNT(*) >= 5
),
common_types AS (
    SELECT DISTINCT wp_type
    FROM web_page wp
    JOIN date_dim cd
        ON wp.wp_creation_date_sk = cd.d_date_sk
    WHERE cd.d_year = 1999
      AND wp.wp_image_count > 2
    INTERSECT
    SELECT DISTINCT wp_type
    FROM web_page wp
    JOIN date_dim cd
        ON wp.wp_access_date_sk = cd.d_date_sk
    WHERE cd.d_year = 1999
      AND wp.wp_image_count > 2
)
SELECT
    a.wp_type,
    a.d_year,
    a.page_cnt,
    a.total_images,
    a.avg_images,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_images DESC) AS img_rank,
    CASE WHEN ct.wp_type IS NOT NULL THEN 'Common' ELSE 'Unique' END AS type_category
FROM agg_stats a
LEFT JOIN common_types ct
    ON a.wp_type = ct.wp_type
WHERE a.wp_type IS NOT NULL
  AND EXISTS (
      SELECT 1
      FROM web_page wp2
      JOIN date_dim cd2
          ON wp2.wp_creation_date_sk = cd2.d_date_sk
      WHERE wp2.wp_type = a.wp_type
        AND cd2.d_year = a.d_year
        AND wp2.wp_image_count > 2
  )
ORDER BY a.d_year, img_rank
LIMIT 100
