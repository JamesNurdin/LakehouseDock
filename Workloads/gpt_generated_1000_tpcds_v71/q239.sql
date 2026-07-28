SELECT DISTINCT
    cc.cc_name,
    cc.cc_city,
    d.d_year,
    d.d_quarter_name
FROM
    call_center AS cc
JOIN
    date_dim AS d
    ON cc.cc_open_date_sk = d.d_date_sk
WHERE
    cc.cc_street_type = 'Boulevard'
    AND d.d_year = 1998
LIMIT 100
