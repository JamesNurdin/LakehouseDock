WITH filtered_reasons AS (
    SELECT
        r_reason_sk,
        CASE
            WHEN r_reason_desc LIKE '%damage%' THEN 'Damaged'
            WHEN r_reason_desc LIKE '%size%' THEN 'Size Issue'
            ELSE 'Other'
        END AS reason_category
    FROM reason
    WHERE r_reason_desc LIKE '%damage%' OR r_reason_desc LIKE '%size%'
)

SELECT
    cr.cr_order_number AS order_number,
    cr.cr_return_amount AS return_amount,
    cr.cr_net_loss AS net_loss,
    fr.reason_category,
    'Catalog' AS source,
    CASE
        WHEN cr.cr_net_loss > 0 THEN 'Loss'
        WHEN cr.cr_net_loss < 0 THEN 'Gain'
        ELSE 'Break-even'
    END AS net_loss_type,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_reason_sk = cr.cr_reason_sk
    ) AS avg_return_amount_by_reason
FROM catalog_returns cr
JOIN filtered_reasons fr
    ON cr.cr_reason_sk = fr.r_reason_sk
WHERE cr.cr_return_quantity > 0
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_reason_sk = cr.cr_reason_sk
          AND sr.sr_return_quantity > 0
    )
UNION ALL
SELECT
    sr.sr_ticket_number AS order_number,
    sr.sr_return_amt AS return_amount,
    sr.sr_net_loss AS net_loss,
    fr.reason_category,
    'Store' AS source,
    CASE
        WHEN sr.sr_net_loss > 0 THEN 'Loss'
        WHEN sr.sr_net_loss < 0 THEN 'Gain'
        ELSE 'Break-even'
    END AS net_loss_type,
    (
        SELECT AVG(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_reason_sk = sr.sr_reason_sk
    ) AS avg_return_amount_by_reason
FROM store_returns sr
JOIN filtered_reasons fr
    ON sr.sr_reason_sk = fr.r_reason_sk
WHERE sr.sr_return_quantity > 0
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_reason_sk = sr.sr_reason_sk
          AND cr.cr_return_quantity > 0
    )
LIMIT 100
