SELECT
    d.d_year AS year,
    COUNT(DISTINCT cc.cc_call_center_sk) AS call_center_opens,
    COUNT(DISTINCT ws.web_site_sk) AS web_site_opens,
    COUNT(DISTINCT wp.wp_web_page_sk) AS web_page_creations
FROM date_dim d
LEFT JOIN call_center cc
    ON cc.cc_open_date_sk = d.d_date_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
GROUP BY d.d_year
ORDER BY d.d_year
