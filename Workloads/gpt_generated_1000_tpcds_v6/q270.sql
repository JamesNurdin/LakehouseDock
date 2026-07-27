WITH first_shift_time AS (
    SELECT t_time_sk
    FROM time_dim
    WHERE t_shift = 'first'
)
SELECT DISTINCT
    src.source_type,
    src.name,
    src.city,
    src.reason,
    src.return_amount
FROM (
    SELECT
        'catalog' AS source_type,
        cc.cc_name AS name,
        w.w_city AS city,
        r.r_reason_desc AS reason,
        cr.cr_return_amount AS return_amount
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN first_shift_time ft ON cr.cr_returned_time_sk = ft.t_time_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'High Risk'
) AS src
UNION ALL
SELECT DISTINCT
    src2.source_type,
    src2.name,
    src2.city,
    src2.reason,
    src2.return_amount
FROM (
    SELECT
        'store' AS source_type,
        CAST(NULL AS varchar) AS name,
        CAST(NULL AS varchar) AS city,
        r.r_reason_desc AS reason,
        sr.sr_return_amt AS return_amount
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN first_shift_time ft ON sr.sr_return_time_sk = ft.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'High Risk'
) AS src2
ORDER BY source_type, return_amount DESC
LIMIT 100
