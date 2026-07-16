SELECT
    cc.cc_division,
    p.p_channel_email,
    COUNT(DISTINCT i.i_item_sk) AS distinct_item_count,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(sr.sr_net_loss) AS store_net_loss,
    SUM(cr.cr_net_loss + sr.sr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(sr.sr_return_quantity) AS avg_store_return_qty,
    COUNT(*) AS total_return_rows
FROM
    catalog_returns cr
JOIN
    item i ON cr.cr_item_sk = i.i_item_sk
JOIN
    call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN
    promotion p ON p.p_item_sk = i.i_item_sk
JOIN
    store_returns sr ON sr.sr_item_sk = i.i_item_sk
WHERE
    cc.cc_hours = '8AM-4PM'
    AND cc.cc_division IN (1, 3)
    AND cc.cc_city = 'Greenwood'
    AND cc.cc_rec_end_date > DATE '2000-01-01'
    AND i.i_category = 'Sports'
    AND p.p_channel_email = 'Y'
    AND cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
GROUP BY
    cc.cc_division,
    p.p_channel_email
HAVING
    SUM(cr.cr_net_loss + sr.sr_net_loss) > 0
ORDER BY
    total_net_loss DESC
LIMIT 100
