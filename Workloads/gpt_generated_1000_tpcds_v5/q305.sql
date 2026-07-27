/* goal: Compare the number of call centers opened vs closed in the year 2000 for each manager, categorizing them by employee size, and keep only categories with more than 5 centers */
SELECT
    cc_manager AS manager,
    'Open' AS metric_type,
    COUNT(*) AS cnt,
    CASE WHEN cc_employees > 100 THEN 'Large' ELSE 'Small' END AS size_category
FROM
    call_center
JOIN
    date_dim ON call_center.cc_open_date_sk = date_dim.d_date_sk
WHERE
    date_dim.d_year = 2000
    AND date_dim.d_current_year = 'Y'
GROUP BY
    cc_manager,
    CASE WHEN cc_employees > 100 THEN 'Large' ELSE 'Small' END
HAVING
    COUNT(*) > 5

UNION ALL

SELECT
    cc_manager AS manager,
    'Closed' AS metric_type,
    COUNT(*) AS cnt,
    CASE WHEN cc_employees > 100 THEN 'Large' ELSE 'Small' END AS size_category
FROM
    call_center
JOIN
    date_dim ON call_center.cc_closed_date_sk = date_dim.d_date_sk
WHERE
    date_dim.d_year = 2000
    AND date_dim.d_current_year = 'Y'
GROUP BY
    cc_manager,
    CASE WHEN cc_employees > 100 THEN 'Large' ELSE 'Small' END
HAVING
    COUNT(*) > 5

ORDER BY
    manager,
    metric_type
LIMIT 100
