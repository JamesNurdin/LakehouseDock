SELECT
    cc.cc_company_name,
    cc.cc_manager,
    cc.cc_tax_percentage,
    cd_closed.d_year AS cc_closed_year,
    cd_open.d_month_seq AS cc_open_month_seq,
    s.s_store_name,
    s.s_state,
    s.s_floor_space,
    sd_closed.d_year AS store_closed_year,
    ws.web_name,
    ws.web_market_manager,
    ws_open.d_year AS web_open_year,
    ws_close.d_year AS web_close_year,
    COUNT(DISTINCT wp.wp_web_page_sk) AS pages_created,
    SUM(wp.wp_max_ad_count) AS total_max_ads,
    MIN(wp.wp_creation_date_sk) AS earliest_page_creation_sk,
    MAX(wp.wp_access_date_sk) AS latest_page_access_sk
FROM call_center cc
JOIN date_dim cd_closed
    ON cc.cc_closed_date_sk = cd_closed.d_date_sk
JOIN date_dim cd_open
    ON cc.cc_open_date_sk = cd_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = cd_closed.d_date_sk
JOIN date_dim sd_closed
    ON s.s_closed_date_sk = sd_closed.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = cd_closed.d_date_sk
JOIN date_dim ws_open
    ON ws.web_open_date_sk = ws_open.d_date_sk
JOIN date_dim ws_close
    ON ws.web_close_date_sk = ws_close.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = cd_closed.d_date_sk
    AND wp.wp_access_date_sk = ws_close.d_date_sk
JOIN date_dim wp_creation
    ON wp.wp_creation_date_sk = wp_creation.d_date_sk
JOIN date_dim wp_access
    ON wp.wp_access_date_sk = wp_access.d_date_sk
WHERE cd_closed.d_year BETWEEN 2000 AND 2020
GROUP BY
    cc.cc_company_name,
    cc.cc_manager,
    cc.cc_tax_percentage,
    cd_closed.d_year,
    cd_open.d_month_seq,
    s.s_store_name,
    s.s_state,
    s.s_floor_space,
    sd_closed.d_year,
    ws.web_name,
    ws.web_market_manager,
    ws_open.d_year,
    ws_close.d_year
ORDER BY pages_created DESC
LIMIT 100
