WITH overall_avg AS (
    SELECT AVG(cr_net_loss) AS avg_net_loss
    FROM catalog_returns
),
refunded AS (
    SELECT
        'Refunded' AS side,
        cust.c_customer_id AS customer_id,
        cr.cr_returned_date_sk AS return_date_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cd.cd_purchase_estimate,
        ca.ca_state,
        CASE
            WHEN cd.cd_purchase_estimate > 8000 THEN 'High'
            WHEN cd.cd_purchase_estimate >= 4000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_category,
        (SELECT avg_net_loss FROM overall_avg) AS overall_avg_net_loss,
        ROW_NUMBER() OVER (
            PARTITION BY CASE
                WHEN cd.cd_purchase_estimate > 8000 THEN 'High'
                WHEN cd.cd_purchase_estimate >= 4000 THEN 'Medium'
                ELSE 'Low'
            END
            ORDER BY cr.cr_net_loss DESC
        ) AS loss_rank
    FROM catalog_returns cr
    JOIN customer cust
        ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_amount > 0
      AND ca.ca_state IN ('CA', 'NY', 'TX')
),
returning AS (
    SELECT
        'Returning' AS side,
        cust.c_customer_id AS customer_id,
        cr.cr_returned_date_sk AS return_date_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cd.cd_purchase_estimate,
        ca.ca_state,
        CASE
            WHEN cd.cd_purchase_estimate > 8000 THEN 'High'
            WHEN cd.cd_purchase_estimate >= 4000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_category,
        (SELECT avg_net_loss FROM overall_avg) AS overall_avg_net_loss,
        ROW_NUMBER() OVER (
            PARTITION BY CASE
                WHEN cd.cd_purchase_estimate > 8000 THEN 'High'
                WHEN cd.cd_purchase_estimate >= 4000 THEN 'Medium'
                ELSE 'Low'
            END
            ORDER BY cr.cr_net_loss DESC
        ) AS loss_rank
    FROM catalog_returns cr
    JOIN customer cust
        ON cr.cr_returning_customer_sk = cust.c_customer_sk
    JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON cr.cr_returning_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_amount > 0
      AND ca.ca_state IN ('CA', 'NY', 'TX')
)
SELECT *
FROM (
    SELECT * FROM refunded
    UNION ALL
    SELECT * FROM returning
) combined
WHERE loss_rank <= 10
ORDER BY purchase_category, loss_rank, overall_avg_net_loss DESC
LIMIT 100
