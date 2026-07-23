SELECT
    r.r_reason_desc,
    COUNT(*) AS return_count,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
    AVG(sr.sr_return_amt_inc_tax) AS avg_return_amount,
    MIN(sr.sr_return_amt_inc_tax) AS min_return_amount,
    MAX(sr.sr_return_amt_inc_tax) AS max_return_amount,
    SUM(sr.sr_fee) AS total_fee,
    SUM(CASE WHEN sr.sr_return_amt_inc_tax > 1000 THEN 1 ELSE 0 END) AS large_return_count,
    SUM(CASE WHEN sr.sr_return_amt_inc_tax <= 1000 THEN 1 ELSE 0 END) AS small_return_count
FROM
    store_returns AS sr
JOIN
    reason AS r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE
    sr.sr_return_amt_inc_tax > 500.00
    AND sr.sr_fee >= 20.00
    AND sr.sr_return_quantity >= 2
    AND sr.sr_cdemo_sk IN (654494, 193988)
    AND r.r_reason_id = 'AAAAAAAALAAAAAAA'
GROUP BY
    r.r_reason_desc
ORDER BY
    total_return_amount DESC
LIMIT 100
