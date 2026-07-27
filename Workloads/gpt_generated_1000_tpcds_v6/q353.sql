SELECT
    d.d_year,
    d.d_week_seq,
    t.t_am_pm,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
WHERE d.d_year = 2001
  AND d.d_week_seq = 11
  AND t.t_am_pm = 'AM'
  AND cr.cr_reversed_charge > 50
GROUP BY d.d_year, d.d_week_seq, t.t_am_pm
HAVING SUM(cr.cr_return_amount) > 1000

UNION ALL

SELECT
    d.d_year,
    d.d_week_seq,
    t.t_am_pm,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
WHERE d.d_year = 2001
  AND d.d_week_seq = 20
  AND t.t_am_pm = 'PM'
  AND cr.cr_reversed_charge > 50
GROUP BY d.d_year, d.d_week_seq, t.t_am_pm
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
