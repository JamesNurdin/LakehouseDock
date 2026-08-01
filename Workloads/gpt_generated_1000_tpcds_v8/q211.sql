SELECT
    t.t_sub_shift,
    COUNT(*) AS returns_cnt,
    SUM(sr.sr_return_amt) AS total_return_amt
FROM
    store_returns sr
JOIN
    time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
WHERE
    t.t_sub_shift = 'morning'
    AND sr.sr_return_amt > 100.0
GROUP BY
    t.t_sub_shift
ORDER BY
    total_return_amt DESC
