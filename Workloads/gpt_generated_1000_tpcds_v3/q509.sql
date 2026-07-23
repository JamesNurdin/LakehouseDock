SELECT
    r.r_reason_desc,
    r.r_reason_id,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
FROM
    web_returns AS wr
JOIN
    reason AS r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE
    wr.wr_return_ship_cost > 500.00
    AND wr.wr_return_tax < 10.00
    AND r.r_reason_desc LIKE '%price%'
GROUP BY
    r.r_reason_desc,
    r.r_reason_id
ORDER BY
    total_return_amount DESC
LIMIT 100
