WITH agg_returns AS (
    SELECT
        ca_ret.ca_state AS returning_state,
        ca_ref.ca_state AS refunded_state,
        COUNT(*) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_quantity,
        SUM(wr.wr_return_amt) / NULLIF(SUM(wr.wr_net_loss), 0) AS return_to_loss_ratio
    FROM web_returns wr
    JOIN customer_address ca_ret
        ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer_address ca_ref
        ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    WHERE ca_ret.ca_state IN ('AZ', 'CO')
      AND ca_ref.ca_zip LIKE '85%'
    GROUP BY ca_ret.ca_state, ca_ref.ca_state
    HAVING SUM(wr.wr_return_amt) > 10000
)
SELECT
    returning_state,
    refunded_state,
    num_returns,
    total_return_amt,
    total_net_loss,
    avg_return_quantity,
    return_to_loss_ratio,
    RANK() OVER (ORDER BY total_return_amt DESC) AS return_rank
FROM agg_returns
ORDER BY total_return_amt DESC
LIMIT 50
