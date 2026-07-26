SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_division,
    cc.cc_employees,
    cc.cc_sq_ft,
    od.d_date AS open_date,
    cd.d_date AS close_date,
    date_diff('day', od.d_date, cd.d_date) AS open_close_days,
    CASE
        WHEN cc.cc_employees > 500 THEN 'Large'
        WHEN cc.cc_employees > 200 THEN 'Medium'
        ELSE 'Small'
    END AS size_category,
    RANK() OVER (PARTITION BY cc.cc_division ORDER BY cc.cc_employees DESC) AS emp_rank_in_division,
    DENSE_RANK() OVER (ORDER BY date_diff('day', od.d_date, cd.d_date) DESC) AS duration_rank
FROM call_center cc
JOIN date_dim od ON cc.cc_open_date_sk = od.d_date_sk
JOIN date_dim cd ON cc.cc_closed_date_sk = cd.d_date_sk
WHERE od.d_year = 2020
