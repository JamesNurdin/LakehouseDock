WITH agg_returns AS (
    SELECT
        cr_warehouse_sk,
        cr_reason_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450874 AND 2451087
    GROUP BY cr_warehouse_sk, cr_reason_sk
)
SELECT
    cr.cr_order_number,
    cc.cc_name,
    cp.cp_department,
    w.w_warehouse_name,
    r.r_reason_desc,
    t.t_hour,
    ca.ca_city,
    cd.cd_education_status,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = cr.cr_warehouse_sk
    ) AS warehouse_return_sum,
    CASE WHEN u.offset_pos = 1 THEN 'gmt_offset' ELSE 'tax_percentage' END AS offset_type,
    u.offset_value
FROM agg_returns ar
JOIN catalog_returns cr
    ON cr.cr_warehouse_sk = ar.cr_warehouse_sk
   AND cr.cr_reason_sk = ar.cr_reason_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
-- expand an array built from two numeric columns of call_center
CROSS JOIN UNNEST(ARRAY[cc.cc_gmt_offset, cc.cc_tax_percentage]) WITH ORDINALITY AS u(offset_value, offset_pos)
-- cross join a small computed set
CROSS JOIN (SELECT 1 AS seq UNION ALL SELECT 2 UNION ALL SELECT 3) AS seqs
WHERE
    cc.cc_state = 'CA'
    AND cp.cp_department = 'DEPARTMENT'
    AND t.t_am_pm = 'PM'
    AND cd.cd_education_status = 'Advanced Degree'
    AND cc.cc_call_center_sk IN (
        SELECT cc2.cc_call_center_sk
        FROM call_center cc2
        WHERE cc2.cc_employees > 200
    )
LIMIT 100
