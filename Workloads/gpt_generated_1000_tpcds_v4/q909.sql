WITH per_customer_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(cr.cr_return_amount) AS cat_return_amount_sum,
        SUM(cr.cr_net_loss) AS cat_net_loss_sum,
        SUM(wr.wr_return_amt) AS web_return_amt_sum,
        SUM(wr.wr_net_loss) AS web_net_loss_sum
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE cr.cr_fee > 5
      AND cr.cr_return_ship_cost < 1000
      AND wr.wr_return_amt > 100
      AND c.c_birth_day BETWEEN 1 AND 31
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT
    ca.c_customer_sk,
    ca.c_first_name,
    ca.c_last_name,
    (ca.cat_return_amount_sum + ca.web_return_amt_sum) AS total_return_amount,
    (ca.cat_net_loss_sum + ca.web_net_loss_sum) AS total_net_loss,
    CASE
        WHEN (ca.cat_net_loss_sum + ca.web_net_loss_sum) > 1000 THEN 'High'
        ELSE 'Low'
    END AS loss_category,
    ROW_NUMBER() OVER (
        PARTITION BY CASE
                        WHEN (ca.cat_net_loss_sum + ca.web_net_loss_sum) > 1000 THEN 'High'
                        ELSE 'Low'
                     END
        ORDER BY (ca.cat_net_loss_sum + ca.web_net_loss_sum) DESC
    ) AS loss_rank
FROM per_customer_agg ca
WHERE ca.c_customer_sk IS NOT NULL
  AND (ca.cat_net_loss_sum + ca.web_net_loss_sum) > 500
ORDER BY total_net_loss DESC
LIMIT 100
