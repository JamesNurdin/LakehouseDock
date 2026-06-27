WITH refunded_addr AS (
    SELECT ca_address_sk, ca_state
    FROM customer_address
),
returning_addr AS (
    SELECT ca_address_sk, ca_state
    FROM customer_address
),
reason_desc AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
),
agg AS (
    SELECT
        r.r_reason_desc,
        ra.ca_state AS refunded_state,
        ta.ca_state AS returning_state,
        COUNT(*) AS return_count,
        SUM(wr.wr_return_quantity) AS total_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN refunded_addr ra ON wr.wr_refunded_addr_sk = ra.ca_address_sk
    JOIN returning_addr ta ON wr.wr_returning_addr_sk = ta.ca_address_sk
    JOIN reason_desc r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_quantity > 0
    GROUP BY r.r_reason_desc, ra.ca_state, ta.ca_state
)
SELECT
    agg.r_reason_desc,
    agg.refunded_state,
    agg.returning_state,
    agg.return_count,
    agg.total_quantity,
    agg.total_return_amount,
    agg.total_net_loss,
    RANK() OVER (PARTITION BY agg.r_reason_desc ORDER BY agg.total_net_loss DESC) AS net_loss_state_rank
FROM agg
ORDER BY agg.total_net_loss DESC
LIMIT 100
