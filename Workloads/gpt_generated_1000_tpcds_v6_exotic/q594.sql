WITH base_returns AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND regexp_like(cc.cc_name, 'Center')
      AND r.r_reason_desc LIKE '%Customer%'
    GROUP BY cc.cc_call_center_sk, cc.cc_name, cc.cc_city, cc.cc_state
),
overall_avg AS (
    SELECT AVG(cr_return_amount) AS overall_avg_return
    FROM (
        SELECT DISTINCT cr_return_amount
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    )
),
ranked AS (
    SELECT
        br.*, 
        RANK() OVER (ORDER BY br.total_return_amount DESC) AS revenue_rank,
        oa.overall_avg_return
    FROM base_returns br
    CROSS JOIN overall_avg oa
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        JOIN reason r2 ON cr2.cr_reason_sk = r2.r_reason_sk
        WHERE cr2.cr_call_center_sk = br.cc_call_center_sk
          AND regexp_like(r2.r_reason_desc, 'Damaged')
    )
)
SELECT
    rr.cc_call_center_sk,
    rr.cc_name,
    rr.cc_city,
    rr.cc_state,
    rr.total_return_amount,
    rr.distinct_orders,
    rr.revenue_rank,
    rr.overall_avg_return,
    CONCAT('CC_', CAST(rr.cc_call_center_sk AS VARCHAR)) AS cc_key
FROM ranked rr
WHERE rr.total_return_amount > rr.overall_avg_return
ORDER BY rr.revenue_rank ASC, rr.cc_name
