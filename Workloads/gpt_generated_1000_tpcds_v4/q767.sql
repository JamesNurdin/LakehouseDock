WITH filtered AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_id,
        r.r_reason_desc,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_quantity,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE
        regexp_like(r.r_reason_desc, '(?i)damaged')
        AND r.r_reason_id LIKE 'AAAA%'
        AND wr.wr_return_amt > 0
)
SELECT
    r_reason_id,
    r_reason_desc,
    concat(r_reason_id, '-', substr(r_reason_desc, 1, 30)) AS reason_key_desc,
    regexp_extract(r_reason_desc, '(\\w+)', 1) AS first_word,
    SUM(wr_return_amt) AS total_return_amount,
    SUM(wr_return_tax) AS total_return_tax,
    COUNT(*) AS return_cnt,
    AVG(wr_return_quantity) AS avg_return_qty,
    CASE
        WHEN SUM(wr_net_loss) > 5000 THEN 'High Loss'
        WHEN SUM(wr_net_loss) > 1000 THEN 'Medium Loss'
        ELSE 'Low Loss'
    END AS loss_category
FROM filtered
GROUP BY
    r_reason_id,
    r_reason_desc,
    concat(r_reason_id, '-', substr(r_reason_desc, 1, 30)),
    regexp_extract(r_reason_desc, '(\\w+)', 1)
ORDER BY total_return_amount DESC
LIMIT 100
