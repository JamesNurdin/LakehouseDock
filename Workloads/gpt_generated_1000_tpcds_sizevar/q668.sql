WITH sampled_returns AS (
    SELECT *
    FROM web_returns
    TABLESAMPLE BERNOULLI (10)
),
union_agg AS (
    SELECT
        r.r_reason_desc AS group_label,
        ca.ca_state AS state,
        SUM(sr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM sampled_returns sr
    JOIN date_dim d
        ON sr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON sr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca
        ON sr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
      AND r.r_reason_desc LIKE '%warranty%'
      AND sr.wr_return_amt > 50
      AND sr.wr_return_tax < 30
      AND ca.ca_state IN ('CA', 'TX')
      AND sr.wr_return_quantity >= 1
      AND sr.wr_fee BETWEEN 0 AND 100
    GROUP BY r.r_reason_desc, ca.ca_state
    HAVING SUM(sr.wr_return_amt) > 100
    UNION
    SELECT
        ca.ca_state AS group_label,
        'ALL' AS state,
        SUM(sr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM sampled_returns sr
    JOIN date_dim d
        ON sr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON sr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca
        ON sr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
      AND r.r_reason_desc LIKE '%warranty%'
      AND sr.wr_return_amt > 50
      AND sr.wr_return_tax < 30
      AND ca.ca_state IN ('CA', 'TX')
      AND sr.wr_return_quantity >= 1
      AND sr.wr_fee BETWEEN 0 AND 100
    GROUP BY ca.ca_state
    HAVING COUNT(*) > 10
)
SELECT
    ua.group_label,
    ua.state,
    ua.total_return_amount,
    ua.return_cnt,
    lt.adjusted_loss
FROM union_agg ua
CROSS JOIN LATERAL (
    SELECT (ua.total_return_amount - ua.return_cnt * 5.00) AS adjusted_loss
) lt
ORDER BY ua.total_return_amount DESC
LIMIT 100
