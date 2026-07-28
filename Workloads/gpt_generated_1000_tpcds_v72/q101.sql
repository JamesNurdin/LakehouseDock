SELECT
    wp_web_page_id,
    wp_url,
    wp_type,
    wp_link_count
FROM
    tpcds.web_page
WHERE
    wp_autogen_flag = 'Y'
    AND wp_link_count >= 10
    AND wp_creation_date_sk IN (2450800, 2450809)
ORDER BY
    wp_link_count DESC,
    wp_web_page_id
LIMIT 100
