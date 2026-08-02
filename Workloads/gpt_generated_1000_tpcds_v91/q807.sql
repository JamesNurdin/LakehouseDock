WITH store_losses AS (
    SELECT
        s.s_state AS region,
        SUM(sr.sr_net_loss) AS net_loss
    FROM
        store_returns sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
        d.d_year = 2021
        AND r.r_reason_id LIKE 'AAAA%'
    GROUP BY
        s.s_state
),
call_center_losses AS (
    SELECT
        cc.cc_state AS region,
        SUM(cr.cr_net_loss) AS net_loss
    FROM
        catalog_returns cr
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE
        d.d_year = 2021
        AND r.r_reason_id LIKE 'AAAA%'
    GROUP BY
        cc.cc_state
),
overall_average AS (
    SELECT AVG(total_loss) AS avg_loss
    FROM (
        SELECT SUM(sr.sr_net_loss) AS total_loss
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2021
        UNION ALL
        SELECT SUM(cr.cr_net_loss) AS total_loss
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2021
    ) t
)
SELECT source, region, net_loss
FROM (
    SELECT 'store' AS source, region, net_loss FROM store_losses
    UNION ALL
    SELECT 'call_center' AS source, region, net_loss FROM call_center_losses
) combined
WHERE net_loss > (SELECT avg_loss FROM overall_average)
ORDER BY net_loss DESC
LIMIT 100
