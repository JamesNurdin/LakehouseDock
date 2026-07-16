WITH aggregated AS (
    SELECT
        ra.ca_state AS returning_state,
        fa.ca_state AS refunded_state,
        t.t_hour AS hour_of_day,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_quantity
    FROM web_returns wr
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer_address ra
        ON wr.wr_returning_addr_sk = ra.ca_address_sk
    JOIN customer_address fa
        ON wr.wr_refunded_addr_sk = fa.ca_address_sk
    WHERE t.t_hour BETWEEN 0 AND 23
    GROUP BY ra.ca_state, fa.ca_state, t.t_hour
    HAVING COUNT(*) > 10
)
SELECT
    returning_state,
    refunded_state,
    hour_of_day,
    total_returns,
    total_return_amount,
    total_net_loss,
    avg_return_quantity,
    total_net_loss / NULLIF(total_returns, 0) AS avg_net_loss_per_return,
    RANK() OVER (PARTITION BY hour_of_day ORDER BY total_net_loss DESC) AS net_loss_rank
FROM aggregated
ORDER BY hour_of_day, net_loss_rank
LIMIT 100
