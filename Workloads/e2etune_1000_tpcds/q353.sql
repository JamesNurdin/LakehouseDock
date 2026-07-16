SELECT
    sm.sm_contract,
    ws.web_city,
    AVG(hd.hd_dep_count) AS avg_dep_count,
    SUM(wp.wp_link_count) AS total_link_count,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages
FROM household_demographics hd
JOIN ship_mode sm
    ON hd.hd_demo_sk = sm.sm_ship_mode_sk
JOIN web_page wp
    ON (hd.hd_demo_sk % 5) = (wp.wp_access_date_sk % 5)
JOIN web_site ws
    ON wp.wp_access_date_sk = ws.web_open_date_sk
WHERE sm.sm_contract IN ('YvxVaJI10', 'ldhM8IvpzHgdbBgDfI')
  AND hd.hd_income_band_sk BETWEEN 2 AND 5
  AND ws.web_state = 'CA'
GROUP BY sm.sm_contract, ws.web_city
HAVING COUNT(*) > 10
ORDER BY avg_dep_count DESC
LIMIT 100
