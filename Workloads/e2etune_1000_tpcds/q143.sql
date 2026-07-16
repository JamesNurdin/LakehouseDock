WITH sales_by_store AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_sales_price) AS avg_sales_price,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY s.s_store_id, s.s_city, s.s_state
    HAVING SUM(ss.ss_net_paid) > 10000
),
returns_by_warehouse AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        cp.cp_department AS department,
        sm.sm_type AS ship_mode_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_transactions
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2453650
      AND cp.cp_department = 'DEPARTMENT'
    GROUP BY w.w_warehouse_id, w.w_city, w.w_state, cp.cp_department, sm.sm_type
    HAVING SUM(cr.cr_return_amount) > 5000
)
SELECT
    'store' AS entity_type,
    s.s_store_id AS entity_id,
    s.s_city,
    s.s_state,
    s.total_sales,
    s.total_profit,
    NULL AS department,
    NULL AS ship_mode_type,
    s.sales_transactions AS transaction_count
FROM sales_by_store s
UNION ALL
SELECT
    'warehouse' AS entity_type,
    r.w_warehouse_id AS entity_id,
    r.w_city,
    r.w_state,
    r.total_return_amount AS total_sales,
    -r.total_net_loss AS total_profit,
    r.department,
    r.ship_mode_type,
    r.return_transactions AS transaction_count
FROM returns_by_warehouse r
ORDER BY total_sales DESC
LIMIT 50
