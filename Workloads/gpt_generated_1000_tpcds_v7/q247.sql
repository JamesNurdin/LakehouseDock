WITH opened AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_manager,
        cc.cc_employees,
        cc.cc_city,
        cc.cc_state,
        d.d_year AS open_year,
        regexp_extract(cc.cc_manager, '^([^ ]+)', 1) AS manager_first_name
    FROM tpcds.call_center cc
    JOIN tpcds.date_dim d
      ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_current_month = 'Y'
      AND regexp_like(cc.cc_mkt_desc, '(?i)development')
      AND cc.cc_manager LIKE '%Ray%'
)
SELECT
    o.open_year,
    o.manager_first_name,
    COUNT(DISTINCT o.cc_call_center_sk) AS centers_count,
    AVG(o.cc_employees) AS avg_employees,
    array_agg(DISTINCT CONCAT(o.cc_city, ', ', o.cc_state)) AS locations
FROM opened o
GROUP BY o.open_year, o.manager_first_name
ORDER BY centers_count DESC
LIMIT 10
