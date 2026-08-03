WITH intersect_customers AS (
    SELECT wr_returning_customer_sk
    FROM web_returns
    WHERE wr_return_amt > 1000
    INTERSECT
    SELECT wr_returning_customer_sk
    FROM web_returns
    WHERE wr_return_quantity > 5
),
raw_state AS (
    SELECT
        r.r_reason_desc,
        ca.ca_state,
        COUNT(*) AS cnt,
        SUM(wr.wr_return_amt) AS sum_amt,
        AVG(wr.wr_return_tax) AS avg_tax,
        ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY SUM(wr.wr_return_amt) DESC) AS rn_state
    FROM web_returns wr
    JOIN customer c_refunded
        ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c_returning
        ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
    JOIN intersect_customers ic
        ON wr.wr_returning_customer_sk = ic.wr_returning_customer_sk
    WHERE
        c_refunded.c_preferred_cust_flag = 'Y'
        AND ca.ca_zip LIKE '9%'
        AND wr.wr_return_amt > 500
        AND wr.wr_return_tax > 5
        AND wr.wr_return_amt < (
            SELECT MAX(wr2.wr_return_amt)
            FROM web_returns wr2
            WHERE wr2.wr_return_quantity = 1
        )
    GROUP BY r.r_reason_desc, ca.ca_state
    HAVING COUNT(*) >= 10
),
state_agg AS (
    SELECT *
    FROM raw_state
    WHERE rn_state <= 5
),
reason_summary AS (
    SELECT
        r_reason_desc,
        AVG(sum_amt) AS avg_state_return_amt,
        SUM(cnt) AS total_cnt,
        ROW_NUMBER() OVER (PARTITION BY r_reason_desc ORDER BY AVG(sum_amt) DESC) AS rn_reason
    FROM state_agg
    GROUP BY r_reason_desc
)
SELECT
    rs.r_reason_desc,
    rs.avg_state_return_amt,
    rs.total_cnt
FROM reason_summary rs
WHERE rs.rn_reason <= 3
ORDER BY rs.avg_state_return_amt DESC
LIMIT 100
