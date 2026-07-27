WITH opened_centers AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_market_manager,
        cc.cc_division,
        cc.cc_employees,
        cc.cc_street_name,
        cc.cc_street_type,
        d_open.d_year AS open_year,
        d_open.d_date AS open_date
    FROM tpcds.call_center cc
    JOIN tpcds.date_dim d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
    WHERE regexp_like(cc.cc_street_name, '^A.*')
      AND cc.cc_street_type LIKE '%avenue%'
)
SELECT
    om.cc_market_manager,
    om.open_year,
    COUNT(*) AS centers_count,
    SUM(om.cc_employees) AS total_employees,
    AVG(om.cc_employees) AS avg_employees,
    CONCAT(om.cc_market_manager, ' (', CAST(om.open_year AS VARCHAR), ')') AS manager_year_label,
    MIN(REGEXP_EXTRACT(om.cc_street_name, '([A-Za-z]+)')) AS sample_street_word
FROM opened_centers om
WHERE om.cc_employees > (
        SELECT AVG(cc2.cc_employees)
        FROM tpcds.call_center cc2
        WHERE cc2.cc_division = om.cc_division
    )
GROUP BY om.cc_market_manager, om.open_year
HAVING COUNT(*) >= 2
ORDER BY total_employees DESC
LIMIT 20
