WITH demo_agg AS (
    SELECT
        hd.hd_demo_sk,
        SUM(cs.cs_net_profit) AS catalog_sales_profit,
        SUM(ss.ss_net_profit) AS store_sales_profit,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(wr.wr_return_amt) AS web_return_amount,
        COUNT(DISTINCT cp.cp_department) AS dept_count
    FROM
        catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN store_sales ss ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN web_returns wr ON wr.wr_reason_sk = r.r_reason_sk
    WHERE
        cp.cp_department = 'Electronics'
        AND sm.sm_carrier IN ('DHL', 'USPS')
        AND w.w_state = 'CA'
        AND r.r_reason_desc LIKE '%defect%'
        AND hd.hd_vehicle_count > 2
        AND cs.cs_quantity > 1
    GROUP BY
        hd.hd_demo_sk
)
SELECT
    da.hd_demo_sk,
    da.catalog_sales_profit,
    da.store_sales_profit,
    da.catalog_return_amount,
    da.web_return_amount,
    da.dept_count,
    (da.catalog_sales_profit + da.store_sales_profit) AS total_profit,
    ROW_NUMBER() OVER (ORDER BY (da.catalog_sales_profit + da.store_sales_profit) DESC) AS overall_rank,
    (SELECT COUNT(*) FROM household_demographics hd2 WHERE hd2.hd_vehicle_count > 2) AS total_hd_with_vehicles
FROM demo_agg da
WHERE
    (da.catalog_sales_profit + da.store_sales_profit) > 1000
    AND da.catalog_return_amount IS NOT NULL
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_hdemo_sk = da.hd_demo_sk
          AND cr2.cr_return_amount > 50
    )
ORDER BY total_profit DESC
LIMIT 100
