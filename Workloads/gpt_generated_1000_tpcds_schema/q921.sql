WITH hd_income AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 10000
      AND ib.ib_upper_bound <= 200000
),
intersect_orders AS (
    SELECT cr_order_number AS order_number
    FROM catalog_returns
    WHERE cr_return_amount > 1000
    INTERSECT
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_return_amt > 500
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_number,
    w.w_warehouse_name,
    w.w_city,
    sm.sm_type,
    r.r_reason_desc,
    cr.cr_return_amount,
    cr.cr_return_tax,
    hdi.hd_buy_potential,
    hdi.ib_lower_bound,
    hdi.ib_upper_bound,
    rc.reason_return_count,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY cr.cr_return_amount DESC) AS warehouse_return_rank,
    LAG(cr.cr_return_amount) OVER (PARTITION BY w.w_warehouse_id ORDER BY cr.cr_return_amount) AS prev_return_amount,
    SUM(cr.cr_return_amount) OVER (PARTITION BY w.w_warehouse_id ORDER BY cr.cr_return_amount ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_return_sum
FROM catalog_returns cr
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN hd_income hdi ON cr.cr_returning_hdemo_sk = hdi.hd_demo_sk
JOIN web_returns wr ON wr.wr_reason_sk = r.r_reason_sk
                      AND wr.wr_returning_hdemo_sk = hdi.hd_demo_sk
JOIN intersect_orders io ON cr.cr_order_number = io.order_number
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS reason_return_count
    FROM catalog_returns cr3
    WHERE cr3.cr_reason_sk = r.r_reason_sk
) rc
WHERE cp.cp_catalog_number IN (12, 13, 20)
  AND w.w_city = 'Lincoln'
  AND sm.sm_type = 'AIR'
  AND r.r_reason_desc LIKE '%Damaged%'
  AND cr.cr_return_amount > 500
  AND hdi.ib_upper_bound <= 200000
ORDER BY warehouse_return_rank
LIMIT 100
