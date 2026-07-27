WITH cat_agg AS (
    SELECT
        cr.cr_reason_sk,
        sm.sm_contract,
        sm.sm_carrier,
        SUM(cr.cr_net_loss) AS catalog_loss
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(sm.sm_contract, '^[A-Z0-9]{5,}$')
      AND r.r_reason_id LIKE 'AAAAAAA%'
    GROUP BY cr.cr_reason_sk, sm.sm_contract, sm.sm_carrier
),
web_agg AS (
    SELECT
        wr.wr_reason_sk,
        SUM(wr.wr_net_loss) AS web_loss
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_id LIKE 'AAAAAAA%'
    GROUP BY wr.wr_reason_sk
)
SELECT
    r.r_reason_desc,
    CONCAT('Contract_', ca.sm_contract) AS contract_label,
    regexp_extract(ca.sm_carrier, '^([A-Z]{2})', 1) AS carrier_prefix,
    ca.catalog_loss,
    wa.web_loss
FROM cat_agg ca
JOIN web_agg wa ON ca.cr_reason_sk = wa.wr_reason_sk
JOIN reason r ON ca.cr_reason_sk = r.r_reason_sk
WHERE ca.catalog_loss > 1000
ORDER BY ca.catalog_loss DESC
LIMIT 100
