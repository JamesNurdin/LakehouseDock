WITH catalog_expanded AS (
    SELECT
        cr.cr_return_quantity,
        CASE WHEN cr.cr_return_quantity > 5 THEN 'Large' ELSE 'Small' END AS return_size,
        sm.sm_carrier AS carrier,
        r.r_reason_desc AS reason_desc,
        cr.cr_net_loss AS net_loss,
        amt_elem AS amount_element
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    CROSS JOIN UNNEST(ARRAY[cr.cr_return_amount, cr.cr_refunded_cash]) AS t(amt_elem)
    WHERE amt_elem > 100
),
catalog_agg AS (
    SELECT
        return_size,
        carrier,
        SUM(net_loss) AS net_loss
    FROM catalog_expanded
    GROUP BY return_size, carrier
),
store_part AS (
    SELECT DISTINCT
        sr.sr_return_quantity,
        CASE WHEN sr.sr_return_quantity > 5 THEN 'Large' ELSE 'Small' END AS return_size,
        CAST(NULL AS varchar) AS carrier,
        r2.r_reason_desc AS reason_desc,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
    JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk
    WHERE sr.sr_return_quantity > 0
),
store_agg AS (
    SELECT
        return_size,
        carrier,
        SUM(net_loss) AS net_loss
    FROM store_part
    GROUP BY return_size, carrier
),
unioned AS (
    SELECT return_size, carrier, net_loss FROM catalog_agg
    UNION
    SELECT return_size, carrier, net_loss FROM store_agg
)
SELECT
    return_size,
    carrier,
    SUM(net_loss) AS total_loss
FROM unioned
GROUP BY ROLLUP (return_size, carrier)
ORDER BY
    return_size,
    carrier
LIMIT 100
