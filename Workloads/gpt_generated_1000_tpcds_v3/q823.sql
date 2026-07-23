WITH cc_dates AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_manager,
        cc.cc_street_type,
        cc.cc_mkt_id,
        cc.cc_employees,
        open_d.d_year AS open_year,
        closed_d.d_year AS closed_year,
        open_d.d_month_seq AS open_month_seq,
        closed_d.d_month_seq AS closed_month_seq,
        open_d.d_current_week AS open_current_week,
        closed_d.d_current_week AS closed_current_week,
        closed_d.d_dom AS closed_dom
    FROM call_center cc
    JOIN date_dim open_d
        ON cc.cc_open_date_sk = open_d.d_date_sk
    JOIN date_dim closed_d
        ON cc.cc_closed_date_sk = closed_d.d_date_sk
    WHERE cc.cc_manager IN ('Clyde Scott', 'Richard James', 'Charles Hinkle')
      AND cc.cc_street_type IN ('Drive', 'Way', 'Boulevard')
      AND cc.cc_mkt_id IN (1, 2, 5)
      AND open_d.d_current_week = 'N'
      AND closed_d.d_dom >= 5
),
aggregated AS (
    SELECT
        cc_dates.cc_mkt_id,
        cc_dates.open_year,
        cc_dates.closed_year,
        COUNT(DISTINCT cc_dates.cc_call_center_id) AS num_centers,
        SUM(cc_dates.cc_employees) AS total_employees,
        AVG(cc_dates.cc_employees) AS avg_employees,
        MAX(cc_dates.cc_employees) AS max_employees
    FROM cc_dates
    GROUP BY cc_dates.cc_mkt_id, cc_dates.open_year, cc_dates.closed_year
    HAVING SUM(cc_dates.cc_employees) > 1000
)
SELECT
    agg.cc_mkt_id,
    agg.open_year,
    agg.closed_year,
    agg.num_centers,
    agg.total_employees,
    agg.avg_employees,
    agg.max_employees,
    (
        SELECT COUNT(*)
        FROM call_center cc2
        WHERE cc2.cc_manager = 'Jack Little' AND cc2.cc_employees > 200
    ) AS cnt_other_managers
FROM aggregated agg
WHERE agg.avg_employees < (
    SELECT AVG(cc_emp)
    FROM (
        SELECT cc.cc_employees AS cc_emp
        FROM call_center cc
        JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
        WHERE d.d_year = agg.open_year
    ) sub
)
ORDER BY agg.total_employees DESC, agg.cc_mkt_id
LIMIT 100
