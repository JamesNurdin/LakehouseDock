SELECT
    cc.cc_market_manager,
    cc.cc_state,
    date_open.d_year AS open_year,
    date_open.d_month_seq AS open_month_seq,
    date_close.d_year AS close_year,
    COUNT(cc.cc_call_center_sk) AS call_center_count,
    SUM(cc.cc_employees) AS total_employees,
    AVG(cc.cc_sq_ft) AS avg_sq_ft,
    MIN(cc.cc_tax_percentage) AS min_tax_percentage,
    MAX(cc.cc_tax_percentage) AS max_tax_percentage,
    (SELECT AVG(cc2.cc_employees)
       FROM call_center cc2
       WHERE cc2.cc_market_manager = cc.cc_market_manager) AS market_manager_avg_employees
FROM
    call_center cc
JOIN date_dim date_open
    ON cc.cc_open_date_sk = date_open.d_date_sk
JOIN date_dim date_close
    ON cc.cc_closed_date_sk = date_close.d_date_sk
WHERE
    cc.cc_market_manager = 'Nicolas Smith'
    AND cc.cc_county IN ('Wadena County', 'San Miguel County')
    AND cc.cc_state = 'CA'
    AND cc.cc_gmt_offset BETWEEN -5.00 AND -3.00
    AND cc.cc_tax_percentage BETWEEN 5.00 AND 10.00
    AND cc.cc_employees > 200
    AND date_open.d_moy = 5
    AND date_open.d_year = 2001
    AND date_open.d_current_year = 'Y'
    AND date_close.d_moy = 8
    AND date_close.d_year = 2002
    AND date_close.d_current_year = 'N'
GROUP BY
    cc.cc_market_manager,
    cc.cc_state,
    date_open.d_year,
    date_open.d_month_seq,
    date_close.d_year
ORDER BY
    total_employees DESC
LIMIT 100
