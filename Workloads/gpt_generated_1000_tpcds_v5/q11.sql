WITH open_cc AS (
    SELECT
        cc.cc_division AS division,
        cc.cc_division_name AS division_name,
        CASE WHEN cc.cc_tax_percentage > 0.05 THEN 'HIGH' ELSE 'LOW' END AS tax_category,
        COUNT(*) AS cnt,
        'OPEN' AS source
    FROM tpcds.call_center cc
    JOIN tpcds.date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND cc.cc_country = 'United States'
    GROUP BY
        cc.cc_division,
        cc.cc_division_name,
        CASE WHEN cc.cc_tax_percentage > 0.05 THEN 'HIGH' ELSE 'LOW' END
),
closed_cc AS (
    SELECT
        cc.cc_division AS division,
        cc.cc_division_name AS division_name,
        CASE WHEN cc.cc_tax_percentage > 0.05 THEN 'HIGH' ELSE 'LOW' END AS tax_category,
        COUNT(*) AS cnt,
        'CLOSED' AS source
    FROM tpcds.call_center cc
    JOIN tpcds.date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND cc.cc_sq_ft > 1000000
    GROUP BY
        cc.cc_division,
        cc.cc_division_name,
        CASE WHEN cc.cc_tax_percentage > 0.05 THEN 'HIGH' ELSE 'LOW' END
)
SELECT
    division,
    division_name,
    tax_category,
    cnt,
    source
FROM open_cc
UNION ALL
SELECT
    division,
    division_name,
    tax_category,
    cnt,
    source
FROM closed_cc
ORDER BY division, tax_category, source
LIMIT 100
