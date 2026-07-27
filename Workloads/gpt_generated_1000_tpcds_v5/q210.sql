WITH returns_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_state,
        cp.cp_department,
        hd.hd_income_band_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_refunded_customers
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE w.w_state IN ('IN', 'AL')
      AND hd.hd_vehicle_count > 0
      AND cp.cp_department = 'Electronics'
      AND cr.cr_return_amount > 50
    GROUP BY w.w_warehouse_id, w.w_state, cp.cp_department, hd.hd_income_band_sk
),
final_agg AS (
    SELECT
        w_state,
        cp_department,
        AVG(total_return_amount) AS avg_return_amount,
        SUM(distinct_refunded_customers) AS total_distinct_customers
    FROM returns_agg
    GROUP BY w_state, cp_department
)
SELECT
    w_state,
    cp_department,
    avg_return_amount,
    total_distinct_customers
FROM final_agg
ORDER BY avg_return_amount DESC
LIMIT 100
