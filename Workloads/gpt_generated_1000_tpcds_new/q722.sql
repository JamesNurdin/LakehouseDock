WITH pages_created_2000 AS (
        SELECT wp.wp_web_page_id
        FROM web_page wp
        JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
        WHERE d.d_year = 2000
          AND wp.wp_autogen_flag = 'N'
    ),
    pages_accessed_2001 AS (
        SELECT wp.wp_web_page_id
        FROM web_page wp
        JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND wp.wp_autogen_flag = 'N'
    ),
    intersect_pages AS (
        SELECT wp_web_page_id
        FROM pages_created_2000
        INTERSECT
        SELECT wp_web_page_id
        FROM pages_accessed_2001
    ),
    full_join_unnest AS (
        SELECT
            wp.wp_web_page_id,
            d.d_date_id,
            CASE ord
                WHEN 1 THEN 'char_count'
                ELSE 'link_count'
            END AS metric_type,
            metric_value
        FROM web_page wp
        FULL OUTER JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
        CROSS JOIN UNNEST(array[wp.wp_char_count, wp.wp_link_count]) WITH ORDINALITY AS t(metric_value, ord)
        WHERE metric_value IS NOT NULL
    )
SELECT
    wp_web_page_id,
    CAST(NULL AS varchar) AS d_date_id,
    CAST(NULL AS varchar) AS metric_type,
    CAST(NULL AS integer) AS metric_value
FROM intersect_pages
UNION
SELECT
    wp_web_page_id,
    d_date_id,
    metric_type,
    metric_value
FROM full_join_unnest
ORDER BY wp_web_page_id
LIMIT 100
