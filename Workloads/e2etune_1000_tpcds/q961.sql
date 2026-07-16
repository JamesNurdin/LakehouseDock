WITH state_returns AS (
    SELECT
        c.c_preferred_cust_flag AS pref_flag,
        ca.ca_state AS state,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        SUM(CASE WHEN td.t_shift = 'Evening' THEN 1 ELSE 0 END) AS evening_returns
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND ca.ca_country = 'United States'
      AND td.t_shift IN ('Evening', 'Night')
    GROUP BY c.c_preferred_cust_flag, ca.ca_state
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT
    pref_flag,
    state,
    distinct_orders,
    total_return_amount,
    total_net_loss,
    avg_return_qty,
    evening_returns,
    RANK() OVER (ORDER BY total_return_amount DESC) AS state_rank
FROM state_returns
ORDER BY total_return_amount DESC
LIMIT 10
