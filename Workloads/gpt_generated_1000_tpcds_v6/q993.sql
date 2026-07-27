WITH customer_losses AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_country,
        c.c_preferred_cust_flag,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_net_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_net_loss,
        SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_tickets,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders
    FROM tpcds.customer c
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE c.c_birth_country = 'KOREA'
      AND c.c_preferred_cust_flag = 'Y'
      AND sr.sr_return_tax > 20
      AND wr.wr_return_amt > 100
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_country,
        c.c_preferred_cust_flag
)
SELECT
    cl.c_customer_id,
    cl.c_birth_country,
    cl.c_preferred_cust_flag,
    cl.store_net_loss,
    cl.web_net_loss,
    cl.total_net_loss,
    cl.distinct_store_tickets,
    cl.distinct_web_orders,
    RANK() OVER (ORDER BY cl.total_net_loss DESC) AS loss_rank,
    CASE
        WHEN cl.total_net_loss > 5000 THEN 'HIGH'
        WHEN cl.total_net_loss > 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_category
FROM customer_losses cl
WHERE cl.total_net_loss > 0
ORDER BY loss_rank
LIMIT 100
