SELECT
    r.r_reason_desc,
    COUNT(*) AS return_count,
    SUM(wr.wr_return_quantity) AS total_quantity,
    SUM(wr.wr_return_amt) AS total_return_amount
FROM
    web_returns wr
JOIN
    reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE
    wr.wr_returning_customer_sk = 7912544
    AND wr.wr_return_ship_cost > 50
GROUP BY
    r.r_reason_desc
ORDER BY
    total_return_amount DESC
LIMIT 100
