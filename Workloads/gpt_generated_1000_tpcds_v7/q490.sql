WITH page_site AS (
    SELECT
        ws.web_name,
        ws.web_state,
        ws.web_city,
        wp.wp_char_count,
        wp.wp_link_count,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
        substring(ws.web_city, 1, 3) AS city_prefix,
        d_page.d_year AS creation_year
    FROM web_page wp
    JOIN date_dim d_page
        ON wp.wp_creation_date_sk = d_page.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_page.d_date_sk
    WHERE regexp_like(wp.wp_url, '\\.com/.*promo')
      AND ws.web_name LIKE '%Online%'
)
SELECT
    ps.web_name,
    ps.web_state,
    ps.city_prefix,
    ps.domain,
    cc.cc_division,
    COUNT(*) AS page_cnt,
    SUM(ps.wp_char_count) AS total_chars,
    AVG(ps.wp_link_count) AS avg_links
FROM page_site ps
JOIN date_dim d_cc
    ON d_cc.d_year = ps.creation_year
JOIN call_center cc
    ON cc.cc_open_date_sk = d_cc.d_date_sk
GROUP BY
    ps.web_name,
    ps.web_state,
    ps.city_prefix,
    ps.domain,
    cc.cc_division
ORDER BY total_chars DESC
LIMIT 20
