WITH refunded AS (
    SELECT 
        cr.cr_warehouse_sk AS warehouse_id,
        'refunded' AS return_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE 
            WHEN SUM(cr.cr_return_amount) > 2000 THEN 'high'
            ELSE 'moderate'
        END AS amount_category
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
        AND cr.cr_return_amount > 500
    GROUP BY cr.cr_warehouse_sk
    HAVING NOT EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = cr.cr_warehouse_sk
          AND cr2.cr_return_amount = 0
    )
),
returning AS (
    SELECT 
        cr.cr_warehouse_sk AS warehouse_id,
        'returning' AS return_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE 
            WHEN SUM(cr.cr_return_amount) > 2000 THEN 'high'
            ELSE 'moderate'
        END AS amount_category
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
        AND cr.cr_return_amount <= 500
    GROUP BY cr.cr_warehouse_sk
    HAVING NOT EXISTS (
        SELECT 1 FROM catalog_returns cr3
        WHERE cr3.cr_warehouse_sk = cr.cr_warehouse_sk
          AND cr3.cr_return_amount = 0
    )
)
SELECT
    warehouse_id,
    return_type,
    total_return_amount,
    total_net_loss,
    amount_category
FROM refunded
UNION ALL
SELECT
    warehouse_id,
    return_type,
    total_return_amount,
    total_net_loss,
    amount_category
FROM returning
ORDER BY total_return_amount DESC
LIMIT 100
