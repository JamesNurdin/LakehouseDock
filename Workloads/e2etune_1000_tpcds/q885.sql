WITH return_pairs AS (
    SELECT
        cr1.cr_order_number,
        cr1.cr_returning_customer_sk AS customer_sk,
        cr1.cr_return_quantity AS qty1,
        cr2.cr_return_quantity AS qty2,
        cr1.cr_net_loss AS net_loss1,
        cr2.cr_net_loss AS net_loss2,
        cr1.cr_return_amount AS amount1,
        cr2.cr_return_amount AS amount2,
        cr1.cr_returned_date_sk AS date_sk,
        cr1.cr_returned_time_sk AS time_sk1,
        cr2.cr_returned_time_sk AS time_sk2
    FROM catalog_returns cr1
    JOIN catalog_returns cr2
        ON cr1.cr_order_number = cr2.cr_order_number
       AND cr1.cr_return_quantity <> cr2.cr_return_quantity
       AND cr1.cr_returned_time_sk < cr2.cr_returned_time_sk
    WHERE (cr1.cr_net_loss + cr2.cr_net_loss) > 100
      AND cr1.cr_return_ship_cost > 0
),
customer_agg AS (
    SELECT
        customer_sk,
        COUNT(*) AS pair_cnt,
        SUM(net_loss1 + net_loss2) AS total_net_loss,
        AVG(amount1 + amount2) AS avg_pair_return_amount,
        MIN(date_sk) AS first_return_date_sk,
        MAX(date_sk) AS last_return_date_sk
    FROM return_pairs
    GROUP BY customer_sk
    HAVING COUNT(*) >= 5
)
SELECT
    ca.customer_sk,
    ca.pair_cnt,
    ca.total_net_loss,
    ca.avg_pair_return_amount,
    ca.first_return_date_sk,
    ca.last_return_date_sk,
    ROW_NUMBER() OVER (ORDER BY ca.total_net_loss DESC) AS loss_rank
FROM customer_agg ca
ORDER BY ca.total_net_loss DESC
LIMIT 10
