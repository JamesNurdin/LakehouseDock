WITH latest_year AS (
    SELECT MAX(d_year) AS yr
    FROM date_dim
    WHERE d_current_month = 'Y'
)
SELECT
    d.d_year AS open_year,
    COUNT(DISTINCT cc.cc_call_center_id) AS distinct_center_cnt,
    AVG(cc.cc_employees) AS avg_employees,
    SUM(CASE WHEN regexp_like(cc.cc_hours, '^8AM-.*$') THEN 1 ELSE 0 END) AS cnt_8am_start,
    CONCAT('Mgr_', regexp_extract(cc.cc_manager, '([A-Z])', 1)) AS manager_initial_code
FROM
    call_center cc
JOIN
    date_dim d
      ON cc.cc_open_date_sk = d.d_date_sk
WHERE
    d.d_year = (SELECT yr FROM latest_year)
    AND regexp_like(cc.cc_name, 'Center')
    AND cc.cc_suite_number LIKE 'Suite %'
    AND EXISTS (
        SELECT 1
        FROM call_center cc2
        WHERE cc2.cc_manager = cc.cc_manager
          AND regexp_like(cc2.cc_suite_number, 'Suite [A-Z]{1}\s+')
    )
GROUP BY
    d.d_year,
    CONCAT('Mgr_', regexp_extract(cc.cc_manager, '([A-Z])', 1))
ORDER BY
    open_year DESC,
    distinct_center_cnt DESC
LIMIT 10
