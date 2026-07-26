SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    d_open.d_date AS open_date,
    d_closed.d_date AS closed_date,
    date_diff('day', d_open.d_date, d_closed.d_date) AS days_open,
    CASE
        WHEN cc.cc_gmt_offset > 0 THEN 'East of GMT'
        WHEN cc.cc_gmt_offset < 0 THEN 'West of GMT'
        ELSE 'GMT'
    END AS gmt_region,
    (cc.cc_employees * 1.0) / NULLIF(cc.cc_sq_ft, 0) AS employees_per_sq_ft,
    RANK() OVER (PARTITION BY cc.cc_division ORDER BY cc.cc_tax_percentage DESC) AS tax_pct_rank_division,
    DENSE_RANK() OVER (ORDER BY cc.cc_employees DESC) AS global_employee_rank
FROM call_center cc
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
WHERE d_closed.d_date IS NOT NULL
ORDER BY cc.cc_division, tax_pct_rank_division
