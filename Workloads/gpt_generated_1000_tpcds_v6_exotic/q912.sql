WITH agg_returns AS (
    SELECT
        cr_ship_mode_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(cr_return_tax) AS avg_return_tax
    FROM catalog_returns
    WHERE cr_return_tax > 5.00
      AND cr_return_amount >= 10.00
    GROUP BY cr_ship_mode_sk
)
SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cd.cd_gender,
    cd.cd_marital_status,
    sm.sm_code,
    sm.sm_contract,
    ar.total_return_amount,
    ar.return_cnt,
    CASE
        WHEN cr.cr_return_tax > 20.00 THEN 'HighTax'
        ELSE 'LowTax'
    END AS tax_category,
    (
        SELECT MAX(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_ship_mode_sk = cr.cr_ship_mode_sk
    ) AS max_return_amount_ship_mode,
    ROW_NUMBER() OVER (PARTITION BY sm.sm_code ORDER BY cr.cr_return_amount DESC) AS rn,
    RANK() OVER (PARTITION BY sm.sm_code ORDER BY cr.cr_return_tax DESC) AS tax_rank
FROM catalog_returns cr
JOIN customer_demographics cd
    ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN agg_returns ar
    ON cr.cr_ship_mode_sk = ar.cr_ship_mode_sk
WHERE cd.cd_dep_employed_count <= 3
  AND sm.sm_contract IN ('HVDFCcQ', 'fop0bcSd91J26IVpR')
  AND cd.cd_gender = 'M'
  AND cr.cr_returning_hdemo_sk IS NOT NULL
ORDER BY rn
LIMIT 100
