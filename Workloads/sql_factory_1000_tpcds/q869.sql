WITH daily_store_loss AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk AS return_date,
        i.i_category,
        ca.ca_state,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk, i.i_category, ca.ca_state
),
store_loss_with_ma AS (
    SELECT
        dsl.*, 
        AVG(total_net_loss) OVER (
            PARTITION BY sr_store_sk, i_category
            ORDER BY return_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS moving_avg_3d,
        CASE
            WHEN total_net_loss > 2 * AVG(total_net_loss) OVER (
                PARTITION BY sr_store_sk, i_category
                ORDER BY return_date
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ) THEN 'Anomalous High Loss'
            WHEN total_net_loss < 0.5 * AVG(total_net_loss) OVER (
                PARTITION BY sr_store_sk, i_category
                ORDER BY return_date
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ) THEN 'Anomalous Low Loss'
            ELSE 'Normal'
        END AS loss_status
    FROM daily_store_loss dsl
)
SELECT
    sr_store_sk,
    ca_state,
    i_category,
    return_date,
    total_net_loss,
    moving_avg_3d,
    loss_status
FROM store_loss_with_ma
WHERE loss_status <> 'Normal'
ORDER BY sr_store_sk, ca_state, i_category, return_date DESC
