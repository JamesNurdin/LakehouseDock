WITH open_holiday AS (
    SELECT
        cc.cc_state AS state,
        d.d_year AS year,
        COUNT(*) AS center_cnt,
        'OpenHoliday' AS scenario
    FROM call_center cc
    JOIN date_dim d
        ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_holiday = 'Y'
    GROUP BY cc.cc_state, d.d_year
),
closed_non_holiday AS (
    SELECT
        cc.cc_state AS state,
        d.d_year AS year,
        COUNT(*) AS center_cnt,
        'ClosedNonHoliday' AS scenario
    FROM call_center cc
    JOIN date_dim d
        ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_holiday = 'N'
    GROUP BY cc.cc_state, d.d_year
)
SELECT *
FROM open_holiday
UNION ALL
SELECT *
FROM closed_non_holiday
ORDER BY state, year, scenario
LIMIT 100
