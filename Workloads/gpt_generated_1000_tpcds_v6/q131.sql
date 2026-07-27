WITH per_state_hour AS (
    SELECT
        ca.ca_state AS state,
        td.t_hour AS hour,
        SUM(wr.wr_net_loss) AS total_loss,
        COUNT(*) AS cnt
    FROM web_returns wr
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE wr.wr_fee > 20
      AND wr.wr_refunded_cash > 30
      AND wr.wr_return_amt_inc_tax > 100
      AND ca.ca_street_type = 'Blvd'
    GROUP BY ca.ca_state, td.t_hour
)
SELECT
    state,
    AVG(total_loss) AS avg_loss_per_hour,
    SUM(cnt) AS total_returns
FROM per_state_hour
GROUP BY state
HAVING SUM(cnt) > 10
ORDER BY avg_loss_per_hour DESC
LIMIT 100
