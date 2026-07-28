WITH date_info AS (
    SELECT d_date_sk,
           d_year,
           d_quarter_name
    FROM date_dim
    WHERE d_year BETWEEN 1995 AND 1998
)
SELECT
    src,
    name_or_url,
    date_sk,
    year,
    category,
    catalog_count,
    (SELECT MAX(cc_closed_date_sk)
     FROM call_center cc_corr
     WHERE cc_corr.cc_open_date_sk = u.date_sk
       AND cc_corr.cc_state = 'CA') AS max_closed_sk
FROM (
    SELECT
        'call_center' AS src,
        cc.cc_name               AS name_or_url,
        cc.cc_open_date_sk       AS date_sk,
        d.d_year                 AS year,
        CASE WHEN cc.cc_employees > 200 THEN 'Large' ELSE 'Small' END AS category,
        (SELECT COUNT(*)
         FROM catalog_page cp
         WHERE cp.cp_start_date_sk = cc.cc_open_date_sk) AS catalog_count
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    JOIN date_info di ON d.d_date_sk = di.d_date_sk
    WHERE cc.cc_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp2
          WHERE cp2.cp_start_date_sk = cc.cc_open_date_sk
      )

    UNION ALL

    SELECT
        'web_page' AS src,
        wp.wp_url                AS name_or_url,
        wp.wp_creation_date_sk   AS date_sk,
        d.d_year                 AS year,
        CASE WHEN wp.wp_type = 'order' THEN 'OrderPage' ELSE 'Other' END AS category,
        (SELECT COUNT(*)
         FROM catalog_page cp
         WHERE cp.cp_end_date_sk = wp.wp_access_date_sk) AS catalog_count
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN date_info di ON d.d_date_sk = di.d_date_sk
    WHERE wp.wp_type LIKE 'order%'
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp2
          WHERE cp2.cp_end_date_sk = wp.wp_access_date_sk
      )
) u
WHERE EXISTS (
    SELECT 1
    FROM catalog_page cp3
    WHERE cp3.cp_start_date_sk = u.date_sk
)
ORDER BY year DESC, catalog_count DESC
LIMIT 100
