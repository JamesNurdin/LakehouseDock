WITH recent_calls AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_hours,
        d.d_year
    FROM call_center cc
    JOIN date_dim d
        ON cc.cc_open_date_sk = d.d_date_sk
    WHERE cc.cc_hours LIKE '%8AM%'
      AND regexp_like(cc.cc_name, '^A.*')
),
web_page_metrics AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_url,
        d.d_year
    FROM web_page wp
    JOIN date_dim d
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE wp.wp_url LIKE 'http%://%example.com/%'
)
SELECT id,
       name_or_url,
       extra_info,
       year,
       source
FROM (
    SELECT
        rc.cc_call_center_id AS id,
        rc.cc_name AS name_or_url,
        concat('Hours:', rc.cc_hours) AS extra_info,
        rc.d_year AS year,
        'call_center' AS source
    FROM recent_calls rc
    UNION ALL
    SELECT
        wpwm.wp_web_page_id AS id,
        wpwm.wp_url AS name_or_url,
        concat('Domain:', regexp_extract(wpwm.wp_url, '(https?://[^/]+)', 1)) AS extra_info,
        wpwm.d_year AS year,
        'web_page' AS source
    FROM web_page_metrics wpwm
) combined
GROUP BY id, name_or_url, extra_info, year, source
HAVING count(*) = 1
ORDER BY year DESC, source
LIMIT 100
