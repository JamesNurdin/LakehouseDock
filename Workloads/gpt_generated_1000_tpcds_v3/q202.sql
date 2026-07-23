WITH open_agg AS (
    SELECT
        cc.cc_division,
        cc.cc_class,
        COUNT(*) AS cc_count,
        AVG(cc.cc_employees) AS avg_employees,
        'opened' AS status
    FROM call_center cc
    JOIN date_dim d
        ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cc.cc_division, cc.cc_class
), closed_agg AS (
    SELECT
        cc.cc_division,
        cc.cc_class,
        COUNT(*) AS cc_count,
        AVG(cc.cc_employees) AS avg_employees,
        'closed' AS status
    FROM call_center cc
    JOIN date_dim d
        ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cc.cc_division, cc.cc_class
)
SELECT
    oa.cc_division,
    oa.cc_class,
    oa.cc_count,
    oa.avg_employees,
    CASE WHEN oa.avg_employees > (SELECT AVG(cc_employees) FROM call_center) THEN true ELSE false END AS above_overall_avg,
    oa.status
FROM open_agg oa
UNION ALL
SELECT
    ca.cc_division,
    ca.cc_class,
    ca.cc_count,
    ca.avg_employees,
    CASE WHEN ca.avg_employees > (SELECT AVG(cc_employees) FROM call_center) THEN true ELSE false END AS above_overall_avg,
    ca.status
FROM closed_agg ca
ORDER BY cc_division, cc_class, status
LIMIT 100
