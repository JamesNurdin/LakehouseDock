WITH refunded AS (
    SELECT
        c.c_customer_id AS customer_id,
        r.r_reason_desc AS reason,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High Loss' ELSE 'Low Loss' END AS loss_category
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE c.c_birth_country IN ('MEXICO', 'PHILIPPINES')
      AND wr.wr_return_ship_cost > 200
    GROUP BY c.c_customer_id, r.r_reason_desc
),
returning AS (
    SELECT
        c.c_customer_id AS customer_id,
        r.r_reason_desc AS reason,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        CASE WHEN SUM(wr.wr_net_loss) > 500 THEN 'High Loss' ELSE 'Low Loss' END AS loss_category
    FROM web_returns wr
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE c.c_birth_country = 'KOREA'
      AND wr.wr_return_ship_cost BETWEEN 100 AND 300
    GROUP BY c.c_customer_id, r.r_reason_desc
)
SELECT
    refunded.customer_id,
    refunded.reason,
    refunded.total_return_amount,
    refunded.loss_category
FROM refunded
UNION ALL
SELECT
    returning.customer_id,
    returning.reason,
    returning.total_return_amount,
    returning.loss_category
FROM returning
ORDER BY total_return_amount DESC
LIMIT 100
