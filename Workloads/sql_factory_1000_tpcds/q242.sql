WITH reason_loss AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        CASE
            WHEN SUM(cr.cr_net_loss) > 10000 THEN 'Very High'
            WHEN SUM(cr.cr_net_loss) > 5000 THEN 'High'
            WHEN SUM(cr.cr_net_loss) > 1000 THEN 'Medium'
            ELSE 'Low'
        END AS loss_category
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY r.r_reason_id, r.r_reason_desc
)
SELECT
    r_reason_id,
    r_reason_desc,
    total_net_loss,
    total_return_amount,
    return_cnt,
    loss_category,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank,
    DENSE_RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM reason_loss
ORDER BY loss_rank
