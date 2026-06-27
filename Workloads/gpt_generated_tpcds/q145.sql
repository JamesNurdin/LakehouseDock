WITH cc_dates AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_class,
        cc.cc_employees,
        cc.cc_sq_ft,
        cc.cc_gmt_offset,
        cc.cc_tax_percentage,
        cc.cc_country,
        cc.cc_division,
        cc.cc_division_name,
        od.d_year AS open_year,
        od.d_date AS open_date,
        cd.d_year AS closed_year,
        cd.d_date AS closed_date,
        date_diff('day', od.d_date, cd.d_date) AS days_open
    FROM call_center cc
    LEFT JOIN date_dim od
        ON cc.cc_open_date_sk = od.d_date_sk
    LEFT JOIN date_dim cd
        ON cc.cc_closed_date_sk = cd.d_date_sk
    WHERE od.d_date >= DATE '2000-01-01'
      AND od.d_date < DATE '2025-01-01'
),
agg AS (
    SELECT
        open_year,
        cc_division,
        cc_division_name,
        COUNT(*) AS num_call_centers,
        AVG(cc_employees) AS avg_employees,
        AVG(cc_sq_ft) AS avg_sq_ft,
        AVG(cc_tax_percentage) AS avg_tax_percentage,
        SUM(days_open) AS total_days_open
    FROM cc_dates
    GROUP BY open_year, cc_division, cc_division_name
)
SELECT
    open_year,
    cc_division,
    cc_division_name,
    num_call_centers,
    avg_employees,
    avg_sq_ft,
    avg_tax_percentage,
    total_days_open,
    RANK() OVER (PARTITION BY open_year ORDER BY avg_employees DESC) AS division_employee_rank
FROM agg
ORDER BY open_year, division_employee_rank
