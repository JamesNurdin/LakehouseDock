/*
Goal: Rank catalog return transactions by amount within each ship mode (AIR or SEA) that have contracts starting with 'U', reasons mentioning "price", and return amount over 100. The query also filters to a specific reason ID, adds a categorical bucket for the amount, computes a cumulative return amount per ship mode, and shows the total number of distinct ship modes meeting the AIR/SEA criteria.
*/
WITH filtered AS (
    SELECT
        cr.cr_returning_hdemo_sk,
        cr.cr_return_quantity,
        cr.cr_return_amt_inc_tax,
        sm.sm_code,
        sm.sm_contract,
        r.r_reason_desc,
        cr.cr_reason_sk
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE sm.sm_code IN ('AIR', 'SEA')                     -- predicate 1
      AND sm.sm_contract LIKE 'U%'                        -- predicate 2
      AND r.r_reason_desc LIKE '%price%'                 -- predicate 3
      AND cr.cr_return_amt_inc_tax > 100                  -- predicate 4
)
SELECT
    fr.cr_returning_hdemo_sk,
    fr.sm_code,
    fr.r_reason_desc,
    fr.cr_return_quantity,
    fr.cr_return_amt_inc_tax,
    SUM(fr.cr_return_amt_inc_tax) OVER (
        PARTITION BY fr.sm_code
        ORDER BY fr.cr_return_amt_inc_tax DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_amt,
    ROW_NUMBER() OVER (
        PARTITION BY fr.sm_code
        ORDER BY fr.cr_return_amt_inc_tax DESC
    ) AS rn,
    RANK() OVER (
        PARTITION BY fr.sm_code
        ORDER BY fr.cr_return_quantity DESC
    ) AS qty_rank,
    CASE
        WHEN fr.cr_return_amt_inc_tax > 500 THEN 'High'
        WHEN fr.cr_return_amt_inc_tax > 200 THEN 'Medium'
        ELSE 'Low'
    END AS amount_category,
    (SELECT COUNT(DISTINCT sm2.sm_code)
     FROM ship_mode sm2
     WHERE sm2.sm_code IN ('AIR', 'SEA')
    ) AS distinct_ship_modes_count
FROM filtered fr
WHERE EXISTS (
    SELECT 1
    FROM reason r2
    WHERE r2.r_reason_sk = fr.cr_reason_sk
      AND r2.r_reason_id = 'AAAAAAAAFAAAAAAA'
)
ORDER BY fr.sm_code, rn
LIMIT 100
