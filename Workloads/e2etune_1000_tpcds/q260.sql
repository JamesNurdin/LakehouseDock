SELECT
    cp.cp_department,
    sm.sm_type,
    ws.web_country,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS num_pages,
    SUM(CASE WHEN cp.cp_type = 'monthly' THEN 1 ELSE 0 END) AS monthly_pages,
    AVG(ws.web_gmt_offset) AS avg_gmt_offset,
    MAX(cp.cp_end_date_sk) AS latest_end_date_sk
FROM
    catalog_page cp
    CROSS JOIN ship_mode sm
    CROSS JOIN web_site ws
WHERE
    cp.cp_type IN ('monthly', 'quarterly')
    AND cp.cp_catalog_number BETWEEN 1 AND 3
    AND cp.cp_start_date_sk >= 2450800
    AND sm.sm_type IN ('AIR', 'GROUND')
    AND ws.web_country = 'United States'
    AND ws.web_state = 'CA'
    AND ws.web_gmt_offset BETWEEN -8 AND -5
GROUP BY
    cp.cp_department,
    sm.sm_type,
    ws.web_country
HAVING
    COUNT(DISTINCT cp.cp_catalog_page_id) >= 5
ORDER BY
    num_pages DESC,
    avg_gmt_offset
LIMIT 100
