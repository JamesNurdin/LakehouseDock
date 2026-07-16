SELECT
    cc_state,
    cc_division_name,
    t_shift,
    centers_cnt,
    total_sq_ft,
    avg_tax_pct,
    min_employees,
    max_employees,
    CASE
        WHEN avg_tax_pct = 0.00 THEN 'Zero'
        WHEN avg_tax_pct <= 0.05 THEN 'Low'
        WHEN avg_tax_pct <= 0.12 THEN 'Medium'
        ELSE 'High'
    END AS tax_category,
    weighted_sq_ft_tax,
    RANK() OVER (PARTITION BY cc_state ORDER BY total_sq_ft DESC) AS state_rank
FROM (
    SELECT
        cc_state,
        cc_division_name,
        t_shift,
        COUNT(DISTINCT cc_call_center_id) AS centers_cnt,
        SUM(cc_sq_ft) AS total_sq_ft,
        AVG(cc_tax_percentage) AS avg_tax_pct,
        MIN(cc_employees) AS min_employees,
        MAX(cc_employees) AS max_employees,
        SUM(cc_sq_ft) * AVG(cc_tax_percentage) AS weighted_sq_ft_tax
    FROM (
        SELECT
            cc.cc_call_center_id,
            cc.cc_state,
            cc.cc_division_name,
            cc.cc_sq_ft,
            cc.cc_employees,
            cc.cc_tax_percentage,
            cc.cc_open_date_sk,
            td.t_shift,
            td.t_hour
        FROM call_center cc
        JOIN time_dim td
          ON cc.cc_open_date_sk = td.t_time_sk
        WHERE cc.cc_state IN ('TN','LA','GA','MI')
          AND cc.cc_tax_percentage >= 0.05
          AND td.t_hour BETWEEN 6 AND 18
    ) s
    GROUP BY cc_state, cc_division_name, t_shift
) g
WHERE centers_cnt >= 5
ORDER BY total_sq_ft DESC
LIMIT 50
