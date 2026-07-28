WITH filtered AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        cp.cp_description,
        sm.sm_carrier,
        w.w_city,
        r.r_reason_desc,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND regexp_like(cp.cp_description, '(?i)sale')
      AND r.r_reason_desc LIKE '%damage%'
      AND w.w_city LIKE 'San%'
)
SELECT
    cp_department,
    cp_type,
    concat(cp_department, '-', cp_type) AS dept_type,
    sm_carrier,
    sum(cr_return_amount) AS total_return_amount,
    sum(cr_return_quantity) AS total_quantity,
    count(*) AS return_cnt,
    sum(cr_net_loss) AS total_net_loss,
    CASE WHEN sum(cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    substring(r_reason_desc, 1, 10) AS short_reason
FROM filtered
GROUP BY
    cp_department,
    cp_type,
    sm_carrier,
    r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
