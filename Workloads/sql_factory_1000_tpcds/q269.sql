WITH cc_dates AS (
    SELECT
        cc.cc_division,
        cc.cc_division_name,
        d_open.d_year AS open_year,
        d_close.d_year AS close_year,
        cc.cc_employees,
        cc.cc_sq_ft,
        cc.cc_tax_percentage,
        cc.cc_name,
        (cc.cc_employees * 1.0 / NULLIF(cc.cc_sq_ft, 0)) AS emp_per_sqft
    FROM call_center cc
    JOIN date_dim d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close
        ON cc.cc_closed_date_sk = d_close.d_date_sk
    WHERE cc.cc_employees IS NOT NULL
      AND cc.cc_sq_ft IS NOT NULL
),
ranked_cc AS (
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY cc_tax_percentage DESC) AS tax_percentage_rank,
        ROW_NUMBER() OVER (PARTITION BY cc_division ORDER BY cc_tax_percentage DESC) AS rn_div,
        AVG(emp_per_sqft) OVER (PARTITION BY cc_division) AS avg_emp_per_sqft_div
    FROM cc_dates
)
SELECT
    cc_division,
    cc_division_name,
    open_year,
    close_year,
    emp_per_sqft,
    cc_tax_percentage,
    tax_percentage_rank,
    avg_emp_per_sqft_div,
    CASE
        WHEN close_year - open_year > 5 THEN 'Long-lived'
        WHEN close_year - open_year BETWEEN 1 AND 5 THEN 'Mid-lived'
        ELSE 'Short-lived'
    END AS lifespan_category
FROM ranked_cc
WHERE rn_div = 1
ORDER BY tax_percentage_rank
