WITH catalog_data AS (
    SELECT
        cr.cr_returned_date_sk AS return_date_sk,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        r.r_reason_desc AS reason_desc,
        ca.ca_state AS state,
        'Catalog' AS channel,
        CASE WHEN cr.cr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
),
store_data AS (
    SELECT
        sr.sr_returned_date_sk AS return_date_sk,
        sr.sr_return_amt AS return_amount,
        sr.sr_net_loss AS net_loss,
        r.r_reason_desc AS reason_desc,
        ca.ca_state AS state,
        'Store' AS channel,
        CASE WHEN sr.sr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2450100
)
SELECT DISTINCT
    return_date_sk,
    return_amount,
    net_loss,
    reason_desc,
    state,
    channel,
    loss_category
FROM (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM store_data
) combined
ORDER BY net_loss DESC
LIMIT 100
