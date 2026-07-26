WITH cat_state AS (
    SELECT 
        ca.ca_state AS state,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss
    FROM catalog_returns cr
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
),
store_state AS (
    SELECT 
        ca.ca_state AS state,
        SUM(sr.sr_return_amt) AS total_store_return_amount,
        SUM(sr.sr_net_loss) AS total_store_net_loss
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
)
SELECT 
    cs.state,
    cs.total_catalog_return_amount,
    ss.total_store_return_amount,
    cs.total_catalog_net_loss,
    ss.total_store_net_loss,
    (cs.total_catalog_return_amount + ss.total_store_return_amount) AS total_return_amount_all,
    CASE 
        WHEN (cs.total_catalog_return_amount + ss.total_store_return_amount) > 100000 THEN 'HIGH'
        WHEN (cs.total_catalog_return_amount + ss.total_store_return_amount) BETWEEN 50000 AND 100000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_volume_category,
    (cs.total_catalog_net_loss + ss.total_store_net_loss) AS total_net_loss_all,
    ROW_NUMBER() OVER (ORDER BY (cs.total_catalog_return_amount + ss.total_store_return_amount) DESC) AS state_return_rank
FROM cat_state cs
JOIN store_state ss ON cs.state = ss.state
ORDER BY state_return_rank
