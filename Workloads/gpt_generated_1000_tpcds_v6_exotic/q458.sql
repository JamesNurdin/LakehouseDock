WITH catalog_enriched AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_net_loss,
        cc.cc_name AS call_center_name,
        td.t_shift,
        td.t_sub_shift
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cr.cr_return_amount > 150
      AND td.t_sub_shift = 'afternoon'
)
SELECT
    source,
    call_center_name,
    t_shift,
    t_sub_shift,
    net_loss,
    loss_category
FROM (
    SELECT
        'Catalog' AS source,
        ce.call_center_name,
        ce.t_shift,
        ce.t_sub_shift,
        ce.cr_net_loss AS net_loss,
        CASE WHEN ce.cr_net_loss > 500 THEN 'High' ELSE 'Normal' END AS loss_category
    FROM catalog_enriched ce

    UNION ALL

    SELECT
        'Store' AS source,
        NULL AS call_center_name,
        td.t_shift,
        td.t_sub_shift,
        sr.sr_net_loss AS net_loss,
        CASE WHEN sr.sr_net_loss > 500 THEN 'High' ELSE 'Normal' END AS loss_category
    FROM store_returns sr
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    WHERE sr.sr_return_amt_inc_tax > 200
      AND td.t_sub_shift = 'afternoon'
) AS combined
ORDER BY loss_category DESC, net_loss DESC
LIMIT 100
