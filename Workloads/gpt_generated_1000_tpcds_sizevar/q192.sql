WITH date_agg AS (
    SELECT
        d_year,
        COUNT(*) AS days_in_year
    FROM tpcds.date_dim
    WHERE d_dow = 1
    GROUP BY d_year
)
SELECT
    cc.cc_state,
    cc.cc_division_name,
    SUM(cc.cc_employees) AS total_employees,
    AVG(cc.cc_sq_ft) AS avg_sq_ft,
    COUNT(DISTINCT cc.cc_company_name) AS distinct_companies,
    MIN(cc.cc_rec_start_date) AS earliest_start,
    MAX(cc.cc_rec_end_date) AS latest_end,
    COUNT(DISTINCT cc.cc_market_manager) AS distinct_market_mgr,
    COUNT(DISTINCT cc.cc_city) AS distinct_cities,
    da.days_in_year,
    RANK() OVER (PARTITION BY cc.cc_state ORDER BY SUM(cc.cc_employees) DESC) AS emp_rank
FROM tpcds.call_center AS cc
JOIN tpcds.date_dim AS d
  ON cc.cc_open_date_sk = d.d_date_sk
JOIN date_agg AS da
  ON d.d_year = da.d_year
WHERE cc.cc_state = 'CA'
  AND cc.cc_gmt_offset BETWEEN -5.00 AND 2.00
  AND d.d_year = 2001
  AND d.d_day_name = 'Monday'
  AND cc.cc_employees > 50
GROUP BY
    cc.cc_state,
    cc.cc_division_name,
    da.days_in_year
ORDER BY cc.cc_state, total_employees DESC
