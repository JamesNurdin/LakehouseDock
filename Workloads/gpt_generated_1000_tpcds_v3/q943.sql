WITH
joined_data AS (
    SELECT
        cr.cr_return_quantity,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_warehouse_sq_ft,
        w.w_suite_number,
        w.w_country
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE
        cp.cp_department IS NOT NULL
        AND cp.cp_catalog_number > 100
        AND cp.cp_catalog_page_number BETWEEN 1 AND 200
        AND cr.cr_return_quantity > 0
        AND cr.cr_return_amt_inc_tax > 50
        AND w.w_country = 'United States'
        AND w.w_warehouse_sq_ft > 10000
        AND w.w_suite_number LIKE 'Suite %'
),
base_agg AS (
    SELECT
        w_warehouse_id,
        w_warehouse_name,
        cp_department,
        SUM(cr_return_amt_inc_tax) AS sum_return_amt_inc_tax,
        SUM(cr_return_quantity) AS sum_return_quantity,
        AVG(cr_return_tax) AS avg_return_tax,
        COUNT(*) AS cnt_returns
    FROM joined_data
    GROUP BY w_warehouse_id, w_warehouse_name, cp_department
),
warehouse_set AS (
    SELECT w_warehouse_id FROM base_agg WHERE sum_return_amt_inc_tax > 50000
    UNION
    SELECT w_warehouse_id FROM base_agg WHERE avg_return_tax > 5
),
dept_agg AS (
    SELECT
        cp_department,
        AVG(sum_return_amt_inc_tax) AS avg_sum_return_amt_inc_tax,
        SUM(sum_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT w_warehouse_id) AS warehouse_count
    FROM base_agg
    WHERE w_warehouse_id IN (SELECT w_warehouse_id FROM warehouse_set)
    GROUP BY cp_department
)
SELECT
    cp_department,
    avg_sum_return_amt_inc_tax,
    total_return_quantity,
    warehouse_count
FROM dept_agg
WHERE avg_sum_return_amt_inc_tax > (
    SELECT AVG(avg_sum_return_amt_inc_tax) FROM dept_agg
)
ORDER BY avg_sum_return_amt_inc_tax DESC
LIMIT 100
