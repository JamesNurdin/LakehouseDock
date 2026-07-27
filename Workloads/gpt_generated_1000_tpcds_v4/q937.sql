WITH selected_reasons AS (
        SELECT r_reason_sk
        FROM reason
        WHERE r_reason_desc LIKE '%product%'
        UNION ALL
        SELECT r_reason_sk
        FROM reason
        WHERE r_reason_desc LIKE '%service%'
    ),
    overall_avg_fee AS (
        SELECT avg(wr_fee) AS avg_fee
        FROM web_returns
    )
SELECT
    ca.ca_state,
    ca.ca_city,
    r.r_reason_desc,
    CASE WHEN wr.wr_fee > 50 THEN 'High' ELSE 'Low' END AS fee_category,
    COUNT(DISTINCT wr.wr_order_number) AS orders_cnt,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(wr.wr_fee) AS avg_fee,
    MIN(wr.wr_return_quantity) AS min_qty,
    MAX(wr.wr_return_tax) AS max_tax,
    (SELECT avg_fee FROM overall_avg_fee) AS overall_avg_fee
FROM web_returns wr
JOIN customer_address ca
    ON wr.wr_refunded_addr_sk = ca.ca_address_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN selected_reasons sr
    ON r.r_reason_sk = sr.r_reason_sk
WHERE
    ca.ca_country = 'United States'
    AND ca.ca_gmt_offset = -5.00
    AND wr.wr_fee > 30
    AND wr.wr_reversed_charge > 100
    AND r.r_reason_desc NOT LIKE '%Not working any more%'
    AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_refunded_addr_sk = wr.wr_refunded_addr_sk
          AND wr2.wr_return_amt > 500
    )
GROUP BY
    ca.ca_state,
    ca.ca_city,
    r.r_reason_desc,
    CASE WHEN wr.wr_fee > 50 THEN 'High' ELSE 'Low' END
ORDER BY total_return_amt DESC
LIMIT 100
