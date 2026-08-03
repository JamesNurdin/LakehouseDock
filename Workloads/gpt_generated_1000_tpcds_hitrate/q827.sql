WITH agg AS (
    SELECT
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_reason_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_returning_hdemo_sk,
        SUM(cr.cr_return_amount) AS total_return,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 0
      AND cr.cr_return_tax >= 0
      AND cr.cr_return_ship_cost >= 0
      AND cr.cr_order_number IS NOT NULL
    GROUP BY CUBE (
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_reason_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_returning_hdemo_sk
    )
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    sm.sm_ship_mode_id,
    sm.sm_code,
    r.r_reason_desc,
    hd_ref.hd_vehicle_count,
    hd_ret.hd_dep_count,
    ib_ref.ib_lower_bound,
    agg.total_return,
    agg.return_cnt,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY agg.total_return DESC) AS dept_rank,
    grp.grp_id
FROM agg
JOIN catalog_page cp
  ON agg.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON agg.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r
  ON agg.cr_reason_sk = r.r_reason_sk
JOIN household_demographics hd_ref
  ON agg.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
  ON agg.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN income_band ib_ref
  ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
CROSS JOIN (
    SELECT DISTINCT sm_code
    FROM ship_mode
    WHERE sm_code IN ('AIR', 'SEA')
) AS sm_codes
CROSS JOIN (
    SELECT 1 AS grp_id UNION ALL SELECT 2 AS grp_id
) AS grp
WHERE cp.cp_catalog_page_id NOT IN (
        SELECT cp2.cp_catalog_page_id
        FROM catalog_page cp2
        WHERE cp2.cp_department = 'Electronics'
      )
  AND sm.sm_type IN ('AIR', 'SEA')
  AND sm.sm_code = sm_codes.sm_code
  AND hd_ref.hd_vehicle_count > 0
  AND hd_ret.hd_dep_count >= 1
  AND ib_ref.ib_lower_bound >= 30000
  AND r.r_reason_id LIKE 'AAAA%'
ORDER BY dept_rank, agg.total_return DESC
LIMIT 100
