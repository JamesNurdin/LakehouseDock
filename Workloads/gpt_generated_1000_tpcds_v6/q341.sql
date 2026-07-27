WITH open_holiday_sites AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        ws.web_suite_number,
        ws.web_city,
        d.d_date,
        d.d_holiday
    FROM web_site ws
    JOIN date_dim d
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_holiday = 'Y'
      AND regexp_like(ws.web_name, '^.*Shop.*$')
      AND ws.web_suite_number LIKE 'Suite %'
)
SELECT
    ods.web_site_id,
    ods.web_name,
    regexp_extract(ods.web_suite_number, 'Suite ([A-Za-z0-9]+)', 1) AS suite_code,
    substring(ods.web_city, 1, 3) AS city_prefix,
    COUNT(DISTINCT ods.d_date) AS holiday_open_days,
    MIN(ods.d_date) AS first_holiday_open,
    MAX(ods.d_date) AS last_holiday_open
FROM open_holiday_sites ods
GROUP BY
    ods.web_site_id,
    ods.web_name,
    regexp_extract(ods.web_suite_number, 'Suite ([A-Za-z0-9]+)', 1),
    substring(ods.web_city, 1, 3)
ORDER BY holiday_open_days DESC, ods.web_site_id
LIMIT 100
