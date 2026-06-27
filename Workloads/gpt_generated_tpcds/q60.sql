WITH cc_dates AS (
    SELECT
        cc.cc_division,
        cc.cc_division_name,
        cc.cc_employees,
        cc.cc_sq_ft,
        cc.cc_tax_percentage,
        d_open.d_year AS open_year,
        d_open.d_date AS open_date,
        d_close.d_date AS close_date
    FROM call_center cc
    JOIN date_dim d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
    LEFT JOIN date_dim d_close
        ON cc.cc_closed_date_sk = d_close.d_date_sk
    WHERE d_open.d_date >= DATE '1995-01-01'
)
SELECT
    cc_division,
    cc_division_name,
    open_year,
    COUNT(*) AS call_center_count,
    AVG(cc_employees) AS avg_employees,
    AVG(cc_sq_ft) AS avg_sq_ft,
    AVG(cc_tax_percentage) AS avg_tax_percentage,
    AVG(date_diff('day', open_date, coalesce(close_date, current_date))) AS avg_days_open
FROM cc_dates
GROUP BY cc_division, cc_division_name, open_year
ORDER BY cc_division, open_year
