WITH per_state AS (
    SELECT
        ca.ca_state AS state,
        cd.cd_gender AS gender,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_refunded_cash) AS avg_refunded_cash,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE ca.ca_state IN ('CA', 'TX', 'NY', 'FL')
      AND cd.cd_gender = 'M'
      AND cd.cd_purchase_estimate > 3000
      AND wr.wr_return_amt > 0
    GROUP BY ca.ca_state, cd.cd_gender
),
overall AS (
    SELECT
        state,
        gender,
        total_return_amt,
        avg_refunded_cash,
        distinct_orders,
        total_net_loss,
        total_return_amt / NULLIF(distinct_orders, 0) AS avg_return_per_order
    FROM per_state
    WHERE total_net_loss > 1000
)
SELECT
    state,
    gender,
    total_return_amt,
    avg_refunded_cash,
    distinct_orders,
    total_net_loss,
    avg_return_per_order,
    ROUND(AVG(total_return_amt) OVER (), 2) AS avg_return_across_states
FROM overall
ORDER BY total_return_amt DESC
LIMIT 100
