WITH return_agg AS (
    SELECT
        cp.cp_department AS department,
        sm.sm_carrier AS carrier,
        sm.sm_contract AS contract,
        hd.hd_buy_potential AS buy_potential,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_quantity,
        AVG(cr.cr_return_amt_inc_tax) AS avg_return_inc_tax,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_return_amount) / NULLIF(COUNT(*), 0) AS avg_return_amount_per_return
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cp.cp_department IN ('Books', 'Electronics', 'Home')
      AND sm.sm_carrier IN ('UPS', 'FEDEX')
      AND sm.sm_contract NOT IN ('P7FBIt8yd')
      AND hd.hd_buy_potential IN ('>10000', '1001-5000')
      AND cr.cr_return_amount > 50
      AND cr.cr_return_quantity >= 1
    GROUP BY cp.cp_department, sm.sm_carrier, sm.sm_contract, hd.hd_buy_potential
),
dept_agg AS (
    SELECT
        department,
        SUM(total_return_amount) AS dept_total_return,
        SUM(total_quantity) AS dept_total_qty,
        AVG(avg_return_amount_per_return) AS dept_avg_return_per,
        COUNT(*) AS dept_return_rows
    FROM (
        SELECT *
        FROM return_agg
        WHERE total_return_amount > 500
    ) filtered
    GROUP BY department
    HAVING AVG(avg_return_amount_per_return) > 100
)
SELECT
    department,
    dept_total_return,
    dept_total_qty,
    dept_avg_return_per,
    dept_return_rows
FROM dept_agg
ORDER BY dept_total_return DESC
LIMIT 100
