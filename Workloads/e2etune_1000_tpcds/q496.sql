WITH returns_per_type AS (
    SELECT
        wp.wp_type,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS num_customers,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_reversed_charge) AS avg_reversed_charge,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN web_page wp
        ON cr.cr_returned_date_sk = wp.wp_access_date_sk
    WHERE cr.cr_return_amt_inc_tax > 500.00
      AND wp.wp_type IS NOT NULL
      AND wp.wp_type <> ''
    GROUP BY wp.wp_type
    HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
    wp_type,
    num_customers,
    total_return_amount,
    avg_reversed_charge,
    total_net_loss,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank,
    SUM(total_return_amount) OVER (ORDER BY total_net_loss DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amount
FROM returns_per_type
ORDER BY total_net_loss DESC
LIMIT 20
