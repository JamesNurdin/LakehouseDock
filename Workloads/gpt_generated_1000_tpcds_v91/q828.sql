WITH demo_info AS (
    SELECT hd_demo_sk,
           hd_vehicle_count,
           hd_dep_count,
           CASE WHEN hd_vehicle_count > 0 THEN 'HasVehicle' ELSE 'NoVehicle' END AS vehicle_flag
    FROM household_demographics
)
SELECT source,
       hd_demo_sk,
       vehicle_flag,
       hd_dep_count,
       transaction_amount,
       amount_size,
       reason_desc,
       total_related_return,
       CASE WHEN total_related_return > 1000 THEN 'HighReturn' ELSE 'LowReturn' END AS return_category
FROM (
    SELECT 'Catalog' AS source,
           d.hd_demo_sk,
           d.vehicle_flag,
           d.hd_dep_count,
           cr.cr_return_amount AS transaction_amount,
           CASE WHEN cr.cr_return_amount > 500 THEN 'Large' ELSE 'Small' END AS amount_size,
           r.r_reason_desc AS reason_desc,
           r_agg.total_reason_return AS total_related_return
    FROM demo_info d
    JOIN catalog_returns cr
        ON cr.cr_refunded_hdemo_sk = d.hd_demo_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    CROSS JOIN LATERAL (
        SELECT SUM(cr2.cr_return_amount) AS total_reason_return
        FROM catalog_returns cr2
        WHERE cr2.cr_reason_sk = r.r_reason_sk
    ) AS r_agg
    WHERE cr.cr_return_amount IS NOT NULL

    UNION ALL

    SELECT 'Store' AS source,
           d.hd_demo_sk,
           d.vehicle_flag,
           d.hd_dep_count,
           sr.sr_return_amt AS transaction_amount,
           CASE WHEN sr.sr_return_amt > 500 THEN 'Large' ELSE 'Small' END AS amount_size,
           r.r_reason_desc AS reason_desc,
           s_agg.total_store_return AS total_related_return
    FROM demo_info d
    JOIN store_returns sr
        ON sr.sr_hdemo_sk = d.hd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    CROSS JOIN LATERAL (
        SELECT SUM(sr2.sr_return_amt) AS total_store_return
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk
    ) AS s_agg
    WHERE sr.sr_return_amt IS NOT NULL
) combined
ORDER BY total_related_return DESC, transaction_amount DESC
LIMIT 100
