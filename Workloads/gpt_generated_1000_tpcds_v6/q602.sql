WITH store_closed AS (
    SELECT
        d.d_year AS year,
        'store_closed' AS entity_type,
        COUNT(DISTINCT s.s_store_sk) AS cnt
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND s.s_zip LIKE '339%'
      AND EXISTS (
          SELECT 1
          FROM store s2
          WHERE s2.s_city = s.s_city
            AND s2.s_number_employees > 150
      )
    GROUP BY d.d_year
),
web_created AS (
    SELECT
        d.d_year AS year,
        'web_page_created' AS entity_type,
        COUNT(DISTINCT wp.wp_web_page_sk) AS cnt
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND wp.wp_link_count > 10
    GROUP BY d.d_year
)
SELECT year, entity_type, cnt
FROM store_closed
UNION ALL
SELECT year, entity_type, cnt
FROM web_created
ORDER BY year DESC, entity_type
LIMIT 100
