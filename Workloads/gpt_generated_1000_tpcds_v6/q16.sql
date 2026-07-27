WITH dept_reason_agg AS (
    SELECT
        cp.cp_department AS department,
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_quantity,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE i.i_rec_start_date >= DATE '1999-01-01'
      AND i.i_rec_end_date <= DATE '2001-12-31'
      AND cp.cp_type = 'Online'
      AND cr.cr_return_quantity > 0
      AND r.r_reason_sk IN (5, 12, 14, 15)
    GROUP BY cp.cp_department, r.r_reason_desc
),
dept_totals AS (
    SELECT
        department,
        SUM(total_return_amount) AS dept_total_return,
        AVG(total_return_amount) AS dept_avg_return
    FROM dept_reason_agg
    GROUP BY department
    HAVING SUM(total_return_amount) > 5000
)
SELECT
    dr.department,
    dr.reason_desc,
    dr.total_return_amount,
    dr.total_quantity,
    dt.dept_total_return,
    dt.dept_avg_return,
    RANK() OVER (PARTITION BY dr.department ORDER BY dr.total_return_amount DESC) AS reason_rank_in_dept,
    SUM(dr.total_return_amount) OVER (PARTITION BY dr.department) AS running_total_by_dept
FROM dept_reason_agg dr
JOIN dept_totals dt ON dr.department = dt.department
WHERE dr.total_return_amount > 1000
ORDER BY dr.department, dr.total_return_amount DESC
LIMIT 100
