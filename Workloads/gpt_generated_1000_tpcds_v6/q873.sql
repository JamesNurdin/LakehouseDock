WITH agg_returns AS (
    SELECT
        cr.cr_call_center_sk,
        cc.cc_name,
        d.d_year,
        t.t_am_pm,
        SUM(cr.cr_return_amount) AS total_return
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year IN (1999, 2000)
    GROUP BY cr.cr_call_center_sk, cc.cc_name, d.d_year, t.t_am_pm
),
combined AS (
    SELECT
        cr_call_center_sk,
        cc_name,
        d_year,
        t_am_pm,
        total_return
    FROM agg_returns
    WHERE t_am_pm = 'AM'
      AND total_return > (SELECT AVG(total_return) FROM agg_returns)
    UNION ALL
    SELECT
        cr_call_center_sk,
        cc_name,
        d_year,
        t_am_pm,
        total_return
    FROM agg_returns
    WHERE t_am_pm = 'PM'
      AND total_return > (SELECT AVG(total_return) FROM agg_returns) * 1.5
)
SELECT
    c.cr_call_center_sk,
    c.cc_name,
    c.d_year,
    SUM(c.total_return) AS total_return_sum,
    COUNT(DISTINCT c.t_am_pm) AS am_pm_covered
FROM combined c
GROUP BY c.cr_call_center_sk, c.cc_name, c.d_year
HAVING SUM(c.total_return) > 50000
ORDER BY total_return_sum DESC
LIMIT 50
