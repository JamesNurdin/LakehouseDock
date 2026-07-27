WITH filtered AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        sm.sm_type,
        sm.sm_contract,
        CASE
            WHEN cr.cr_return_amount > 1000 THEN 'HIGH'
            WHEN cr.cr_return_amount > 500 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS return_level,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_return_ship_cost,
        sm.sm_ship_mode_sk
    FROM catalog_page cp
    JOIN catalog_returns cr
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cp.cp_type IN ('bi-annual', 'monthly')
      AND cp.cp_catalog_page_id LIKE 'AAAAAAA%'
      AND sm.sm_type = 'EXPRESS'
      AND sm.sm_contract LIKE 'A%'
      AND cr.cr_return_ship_cost > 0
      AND cr.cr_returned_date_sk BETWEEN 2450900 AND 2451100
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_ship_mode_sk = sm.sm_ship_mode_sk
            AND cr2.cr_return_amount > 2000
      )
),
agg AS (
    SELECT
        cp_department,
        cp_type,
        sm_type,
        sm_contract,
        return_level,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_quantity,
        AVG(cr_return_ship_cost) AS avg_ship_cost,
        COUNT(*) AS return_cnt
    FROM filtered
    GROUP BY cp_department, cp_type, sm_type, sm_contract, return_level
)
SELECT
    cp_department,
    cp_type,
    sm_type,
    sm_contract,
    return_level,
    total_return_amount,
    total_quantity,
    avg_ship_cost,
    return_cnt,
    RANK() OVER (PARTITION BY cp_department ORDER BY total_return_amount DESC) AS dept_return_rank,
    SUM(total_return_amount) OVER (PARTITION BY sm_type ORDER BY total_return_amount ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_by_ship_type
FROM agg
ORDER BY cp_department, dept_return_rank
