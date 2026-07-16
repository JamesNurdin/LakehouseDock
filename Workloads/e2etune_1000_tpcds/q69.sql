WITH returned_by_time AS (
    SELECT
        ca_returning.ca_city AS returning_city,
        ca_returning.ca_state AS returning_state,
        ca_refunded.ca_city AS refunded_city,
        ca_refunded.ca_state AS refunded_state,
        t.t_hour,
        t.t_am_pm,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_quantity,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    WHERE ca_returning.ca_gmt_offset BETWEEN -8.00 AND -5.00
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY ca_returning.ca_city, ca_returning.ca_state,
             ca_refunded.ca_city, ca_refunded.ca_state,
             t.t_hour, t.t_am_pm
)
SELECT
    returning_city,
    returning_state,
    refunded_city,
    refunded_state,
    t_hour,
    t_am_pm,
    total_return_amt,
    total_quantity,
    avg_return_amt_inc_tax,
    distinct_orders,
    total_net_loss,
    RANK() OVER (ORDER BY total_return_amt DESC) AS return_rank
FROM returned_by_time
WHERE total_return_amt > 5000
ORDER BY total_return_amt DESC
LIMIT 100
