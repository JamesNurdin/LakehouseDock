SELECT
    r.r_reason_desc,
    COUNT(*) AS return_count,
    SUM(wr.wr_return_amt) AS total_return_amount
FROM
    web_returns wr
JOIN
    reason r
      ON wr.wr_reason_sk = r.r_reason_sk
WHERE
    wr.wr_returning_addr_sk = 3953141
    AND r.r_reason_id = 'AAAAAAAALAAAAAAA'
GROUP BY
    r.r_reason_desc
ORDER BY
    total_return_amount DESC
LIMIT 100
