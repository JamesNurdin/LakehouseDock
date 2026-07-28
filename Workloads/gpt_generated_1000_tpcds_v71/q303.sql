SELECT wp_url,
       d_year,
       total_chars
FROM (
    SELECT wp.wp_url AS wp_url,
           d.d_year AS d_year,
           SUM(wp.wp_char_count) AS total_chars
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 1905
      AND wp.wp_type = 'Home'
      AND EXISTS (
          SELECT 1
          FROM web_page wp2
          WHERE wp2.wp_customer_sk = wp.wp_customer_sk
            AND wp2.wp_char_count > 4000
      )
    GROUP BY wp.wp_url, d.d_year
    HAVING SUM(wp.wp_char_count) > (
        SELECT AVG(wp3.wp_char_count)
        FROM web_page wp3
    )
    UNION ALL
    SELECT wp.wp_url AS wp_url,
           d.d_year AS d_year,
           SUM(wp.wp_char_count) AS total_chars
    FROM web_page wp
    JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 1905
      AND wp.wp_type = 'Content'
      AND EXISTS (
          SELECT 1
          FROM web_page wp2
          WHERE wp2.wp_customer_sk = wp.wp_customer_sk
            AND wp2.wp_char_count > 4000
      )
    GROUP BY wp.wp_url, d.d_year
    HAVING SUM(wp.wp_char_count) > (
        SELECT AVG(wp3.wp_char_count)
        FROM web_page wp3
    )
) AS combined
ORDER BY total_chars DESC
LIMIT 100
