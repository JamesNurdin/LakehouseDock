WITH sampled_cr AS (
    SELECT cr.*
    FROM catalog_returns cr
    TABLESAMPLE BERNOULLI (10)
),
sampled_wr AS (
    SELECT wr.*
    FROM web_returns wr
    TABLESAMPLE BERNOULLI (10)
),
shared_orders AS (
    SELECT cr_order_number
    FROM sampled_cr
    INTERSECT
    SELECT wr_order_number
    FROM sampled_wr
),
joined AS (
    SELECT
        cr.cr_order_number,
        cp.cp_department,
        cp.cp_catalog_number,
        sm.sm_type,
        r.r_reason_desc,
        td.t_hour,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_ship_cost,
        cr.cr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        lt.total_return_inc_tax
    FROM sampled_cr cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN shared_orders so
        ON cr.cr_order_number = so.cr_order_number
    JOIN sampled_wr wr
        ON wr.wr_order_number = cr.cr_order_number
        AND wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    CROSS JOIN LATERAL (
        SELECT cr.cr_return_amount + cr.cr_return_tax AS total_return_inc_tax
    ) lt
),
aggregated AS (
    SELECT
        cp_department,
        cp_catalog_number,
        sm_type,
        r_reason_desc,
        t_hour,
        CASE 
            WHEN sm_type = 'EXPRESS' THEN 'Fast'
            WHEN sm_type = 'OVERNIGHT' THEN 'Fast'
            ELSE 'Standard'
        END AS shipping_speed_category,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_tax) AS total_return_tax,
        SUM(cr_return_ship_cost) AS total_ship_cost,
        SUM(wr_return_amt) AS total_web_return_amount,
        SUM(wr_return_tax) AS total_web_return_tax
    FROM joined
    WHERE t_hour BETWEEN 9 AND 17
      AND cr_return_amount > 100
      AND sm_type IN ('EXPRESS', 'OVERNIGHT')
    GROUP BY
        cp_department,
        cp_catalog_number,
        sm_type,
        r_reason_desc,
        t_hour,
        CASE 
            WHEN sm_type = 'EXPRESS' THEN 'Fast'
            WHEN sm_type = 'OVERNIGHT' THEN 'Fast'
            ELSE 'Standard'
        END
)
SELECT
    cp_department,
    cp_catalog_number,
    sm_type,
    shipping_speed_category,
    r_reason_desc,
    t_hour,
    total_return_amount,
    total_return_tax,
    total_ship_cost,
    total_web_return_amount,
    total_web_return_tax,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_return_amount DESC) AS dept_return_rank
FROM aggregated
ORDER BY cp_department, dept_return_rank
