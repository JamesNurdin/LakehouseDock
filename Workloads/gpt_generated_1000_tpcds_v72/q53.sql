WITH cc_open_closed AS (
    SELECT
        cc.cc_state                                  AS state,
        cc.cc_country                               AS country,
        cc.cc_employees                             AS employees,
        cc.cc_sq_ft                                 AS sq_ft,
        CASE WHEN cc.cc_employees >= 1000 THEN 'Large' ELSE 'Small' END AS size_category,
        od.d_year                                   AS open_year,
        od.d_month_seq                              AS open_month_seq,
        cd.d_year                                   AS closed_year,
        cd.d_month_seq                              AS closed_month_seq
    FROM tpcds.call_center cc
    JOIN tpcds.date_dim od ON cc.cc_open_date_sk = od.d_date_sk
    JOIN tpcds.date_dim cd ON cc.cc_closed_date_sk = cd.d_date_sk
    WHERE cc.cc_state IN ('CA', 'TX', 'NY', 'FL')
      AND cc.cc_country = 'United States'
      AND cc.cc_gmt_offset BETWEEN -5 AND 5
      AND od.d_current_month = 'Y'
)
SELECT
    sub.state,
    sub.country,
    sub.size_category,
    COUNT(*)               AS cnt_centers,
    SUM(sub.sq_ft)         AS total_sq_ft,
    AVG(sub.sq_ft)         AS avg_sq_ft
FROM (
    SELECT
        state,
        country,
        size_category,
        sq_ft
    FROM cc_open_closed
    WHERE open_year = 2005
      AND closed_year >= 2010
) sub
GROUP BY sub.state, sub.country, sub.size_category
HAVING SUM(sub.sq_ft) > 1000000
ORDER BY avg_sq_ft DESC
LIMIT 100
