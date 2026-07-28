WITH filtered_returns AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_id,
        r.r_reason_desc,
        regexp_extract(r.r_reason_desc, '(\\w+)') AS first_word,
        substring(r.r_reason_desc, 1, 10) AS desc_prefix,
        CONCAT(r.r_reason_id, '_', regexp_extract(r.r_reason_desc, '(\\w+)')) AS reason_key,
        CASE
            WHEN regexp_like(r.r_reason_desc, '(?i)not') THEN 'Contains_NOT'
            ELSE 'Other'
        END AS not_flag,
        w.wr_return_amt_inc_tax,
        w.wr_return_ship_cost,
        w.wr_return_quantity
    FROM tpcds.reason r
    JOIN tpcds.web_returns w
        ON w.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%product%'
      AND regexp_like(r.r_reason_desc, '(?i)not')
)
SELECT
    r_reason_id,
    first_word,
    desc_prefix,
    reason_key,
    not_flag,
    COUNT(*) AS returns_cnt,
    SUM(wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
    AVG(wr_return_ship_cost) AS avg_ship_cost,
    SUM(wr_return_quantity) AS total_quantity
FROM filtered_returns
GROUP BY r_reason_id, first_word, desc_prefix, reason_key, not_flag
ORDER BY total_return_amt_inc_tax DESC
LIMIT 10
