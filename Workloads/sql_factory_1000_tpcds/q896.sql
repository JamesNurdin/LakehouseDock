WITH dept_shift_detail AS (
    SELECT
        cp.cp_department,
        td.t_shift,
        r.r_reason_desc,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        CASE
            WHEN cr.cr_return_amount < 100 THEN 'Low'
            WHEN cr.cr_return_amount BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High'
        END AS amount_category,
        ROW_NUMBER() OVER (PARTITION BY cp.cp_department, td.t_shift ORDER BY cr.cr_return_amount DESC) AS rn
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
)
SELECT
    cp_department,
    t_shift,
    amount_category,
    COUNT(*) AS num_returns,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_net_loss) AS total_net_loss,
    MAX(rn) AS max_rank_in_category
FROM dept_shift_detail
WHERE rn <= 5
GROUP BY cp_department, t_shift, amount_category
ORDER BY cp_department, t_shift, amount_category
