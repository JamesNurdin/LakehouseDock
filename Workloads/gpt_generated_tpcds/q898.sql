WITH refunded AS (
    SELECT 
        ca.ca_state AS state,
        'refunded' AS address_type,
        COUNT(*) AS return_count,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(wr.wr_return_quantity) AS avg_return_quantity
    FROM web_returns wr
    JOIN customer_address ca
      ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
),
returning AS (
    SELECT 
        ca.ca_state AS state,
        'returning' AS address_type,
        COUNT(*) AS return_count,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(wr.wr_return_quantity) AS avg_return_quantity
    FROM web_returns wr
    JOIN customer_address ca
      ON wr.wr_returning_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
)
SELECT 
    state,
    address_type,
    return_count,
    total_net_loss,
    total_return_amount,
    avg_return_quantity
FROM refunded
UNION ALL
SELECT 
    state,
    address_type,
    return_count,
    total_net_loss,
    total_return_amount,
    avg_return_quantity
FROM returning
ORDER BY state, address_type
