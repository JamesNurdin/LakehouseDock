WITH filtered AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_reason_sk,
        cr.cr_returned_time_sk
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)service|size')
      AND t.t_sub_shift LIKE 'morning%'
)
SELECT
    r.r_reason_id,
    r.r_reason_desc,
    regexp_extract(r.r_reason_desc, '^([A-Za-z]+)', 1) AS first_word,
    concat(r.r_reason_id, '-', r.r_reason_desc) AS reason_key_desc,
    COUNT(*) AS return_cnt,
    SUM(f.cr_return_amount) AS total_return_amount,
    AVG(f.cr_net_loss) AS avg_net_loss,
    MIN(t.t_hour) AS earliest_hour,
    MAX(t.t_hour) AS latest_hour
FROM filtered f
JOIN reason r ON f.cr_reason_sk = r.r_reason_sk
JOIN time_dim t ON f.cr_returned_time_sk = t.t_time_sk
GROUP BY
    r.r_reason_id,
    r.r_reason_desc,
    regexp_extract(r.r_reason_desc, '^([A-Za-z]+)', 1),
    concat(r.r_reason_id, '-', r.r_reason_desc)
ORDER BY total_return_amount DESC
LIMIT 5
