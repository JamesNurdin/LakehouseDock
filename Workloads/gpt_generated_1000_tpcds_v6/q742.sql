SELECT
    date_sk,
    net_loss,
    reason_desc,
    gender,
    return_source,
    loss_category
FROM (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_net_loss AS net_loss,
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        'store' AS return_source,
        CASE WHEN sr.sr_net_loss > 100 THEN 'high' ELSE 'low' END AS loss_category
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_return_ship_cost > 20

    UNION ALL

    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_net_loss AS net_loss,
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        'catalog' AS return_source,
        CASE WHEN cr.cr_net_loss > 100 THEN 'high' ELSE 'low' END AS loss_category
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_return_quantity > 1
) AS combined
ORDER BY date_sk DESC, loss_category
LIMIT 100
