WITH refunded_agg AS (
    SELECT
        wr_refunded_customer_sk AS customer_sk,
        COUNT(*) AS num_refunds,
        SUM(wr_return_amt) AS total_return_amount,
        SUM(wr_refunded_cash) AS total_refunded_cash
    FROM web_returns
    GROUP BY wr_refunded_customer_sk
),
returning_agg AS (
    SELECT
        wr_returning_customer_sk AS customer_sk,
        COUNT(*) AS num_returns,
        SUM(wr_return_quantity) AS total_return_qty,
        SUM(wr_net_loss) AS total_net_loss
    FROM web_returns
    GROUP BY wr_returning_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_year,
    COALESCE(rf.num_refunds, 0) AS num_refunds,
    COALESCE(rf.total_return_amount, 0) AS total_return_amount,
    COALESCE(rf.total_refunded_cash, 0) AS total_refunded_cash,
    COALESCE(rt.num_returns, 0) AS num_returns,
    COALESCE(rt.total_return_qty, 0) AS total_return_qty,
    COALESCE(rt.total_net_loss, 0) AS total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY c.c_birth_year ORDER BY COALESCE(rf.total_return_amount, 0) DESC) AS rank_by_return_amount
FROM customer c
LEFT JOIN refunded_agg rf
    ON rf.customer_sk = c.c_customer_sk
LEFT JOIN returning_agg rt
    ON rt.customer_sk = c.c_customer_sk
ORDER BY c.c_birth_year, rank_by_return_amount
