/*
Goal: Compare the net loss of product returns from stores and catalog channels by return reason during business hours (09:00–17:00).
The query unions detailed return rows from STORE_RETURNS and CATALOG_RETURNS, each joined to REASON for textual descriptions and to TIME_DIM to filter on the hour of the return. The final result is ordered by net loss descending.
*/
WITH store_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        sr.sr_net_loss   AS net_loss,
        'store'           AS source
    FROM store_returns sr
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
),
catalog_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cr.cr_net_loss   AS net_loss,
        'catalog'        AS source
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
)
SELECT reason_desc,
       net_loss,
       source
FROM store_ret
UNION ALL
SELECT reason_desc,
       net_loss,
       source
FROM catalog_ret
ORDER BY net_loss DESC
