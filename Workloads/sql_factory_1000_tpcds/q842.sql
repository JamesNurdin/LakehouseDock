WITH customer_returns AS (
    SELECT cr.cr_refunded_customer_sk AS customer_sk,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    UNION ALL
    SELECT wr.wr_refunded_customer_sk AS customer_sk,
           wr.wr_net_loss AS net_loss
    FROM web_returns wr
),
customer_agg AS (
    SELECT
        customer_sk,
        SUM(net_loss) AS total_net_loss
    FROM customer_returns
    GROUP BY customer_sk
)
SELECT
    ca.customer_sk,
    ca.total_net_loss,
    CASE
        WHEN ca.total_net_loss > 20000 THEN 'VIP_HIGH_LOSS'
        WHEN ca.total_net_loss > 10000 THEN 'VIP_MEDIUM_LOSS'
        ELSE 'VIP_LOW_LOSS'
    END AS loss_tier,
    SUM(ca.total_net_loss) OVER (ORDER BY ca.total_net_loss DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss,
    RANK() OVER (ORDER BY ca.total_net_loss DESC) AS loss_rank
FROM customer_agg ca
ORDER BY total_net_loss DESC
LIMIT 20
