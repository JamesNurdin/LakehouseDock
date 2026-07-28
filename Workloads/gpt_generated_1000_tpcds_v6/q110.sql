WITH cc_closed AS (
    SELECT
        cc.cc_division_name AS division_name,
        d.d_year AS closed_year,
        SUM(cc.cc_sq_ft) AS sum_sq_ft,
        AVG(cc.cc_employees) AS avg_employees,
        COUNT(*) AS cnt_centers,
        SUM(CASE WHEN cc.cc_tax_percentage > 5.00 THEN 1 ELSE 0 END) AS high_tax_cnt
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE cc.cc_state = 'CA'                                   -- predicate 1
      AND cc.cc_gmt_offset BETWEEN -8.00 AND -5.00             -- predicate 2
      AND d.d_current_year = 'Y'                               -- predicate 3
    GROUP BY cc.cc_division_name, d.d_year
)
SELECT
    closed_year,
    size_bucket,
    COUNT(*) AS divisions_in_bucket,
    AVG(sum_sq_ft) AS avg_sq_ft_per_division,
    AVG(avg_employees) AS avg_employees_per_division,
    SUM(high_tax_cnt) AS total_high_tax_centers
FROM (
    SELECT
        division_name,
        closed_year,
        sum_sq_ft,
        avg_employees,
        cnt_centers,
        high_tax_cnt,
        CASE
            WHEN sum_sq_ft > 500000 THEN 'Large'
            WHEN sum_sq_ft > 200000 THEN 'Medium'
            ELSE 'Small'
        END AS size_bucket
    FROM cc_closed
    WHERE cnt_centers >= 5                                     -- outer filter
) agg2
GROUP BY closed_year, size_bucket
HAVING AVG(sum_sq_ft) > 100000
ORDER BY closed_year DESC, avg_sq_ft_per_division DESC
LIMIT 100
