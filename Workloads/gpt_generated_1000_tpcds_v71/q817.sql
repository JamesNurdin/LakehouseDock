WITH base AS (
    SELECT
        wr.wr_returned_time_sk,
        wr.wr_returning_addr_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_reason_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 0
)

SELECT *
FROM (
    SELECT DISTINCT
        r.r_reason_desc,
        t.t_hour,
        COUNT(*) AS return_cnt,
        SUM(b.wr_return_amt) AS total_return_amount
    FROM base b
    JOIN reason r ON b.wr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON b.wr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca ON b.wr_returning_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY r.r_reason_desc, t.t_hour
    UNION ALL
    SELECT
        r.r_reason_desc,
        t.t_hour,
        COUNT(*) AS return_cnt,
        SUM(b.wr_return_amt) AS total_return_amount
    FROM base b
    JOIN reason r ON b.wr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON b.wr_returned_time_sk = t.t_time_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM customer_address ca2
        WHERE ca2.ca_address_sk = b.wr_refunded_addr_sk
    )
      AND t.t_hour < 9
    GROUP BY r.r_reason_desc, t.t_hour
) AS combined
ORDER BY return_cnt DESC, total_return_amount DESC
LIMIT 100
