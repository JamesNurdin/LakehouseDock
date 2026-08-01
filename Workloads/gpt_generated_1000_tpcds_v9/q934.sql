WITH high_agg AS (
    SELECT 
        d.d_date,
        d.d_year,
        w.w_warehouse_name,
        w.w_warehouse_sk,
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 100
      AND d.d_year = 2000
      AND r.r_reason_desc = 'Customer Not At Home'
      AND w.w_state = 'CA'
      AND ca.ca_zip = '10069'
    GROUP BY 
        d.d_date,
        d.d_year,
        w.w_warehouse_name,
        w.w_warehouse_sk,
        r.r_reason_desc
),
low_agg AS (
    SELECT 
        d.d_date,
        d.d_year,
        w.w_warehouse_name,
        w.w_warehouse_sk,
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca
        ON cr.cr_returning_addr_sk = ca.ca_address_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount <= 50
      AND d.d_year = 2000
      AND r.r_reason_desc = 'Damaged'
      AND w.w_state = 'NY'
      AND ca.ca_zip = '98579'
    GROUP BY 
        d.d_date,
        d.d_year,
        w.w_warehouse_name,
        w.w_warehouse_sk,
        r.r_reason_desc
)
SELECT 
    u.d_date,
    u.d_year,
    u.w_warehouse_name,
    u.w_warehouse_sk,
    u.reason_desc,
    u.total_return_amount,
    u.return_count
FROM (
    SELECT 
        d_date,
        d_year,
        w_warehouse_name,
        w_warehouse_sk,
        reason_desc,
        total_return_amount,
        return_count
    FROM high_agg
    UNION ALL
    SELECT 
        d_date,
        d_year,
        w_warehouse_name,
        w_warehouse_sk,
        reason_desc,
        total_return_amount,
        return_count
    FROM low_agg
) u
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr3
    JOIN warehouse w3
        ON cr3.cr_warehouse_sk = w3.w_warehouse_sk
    WHERE w3.w_warehouse_sk = u.w_warehouse_sk
      AND cr3.cr_return_amount > 200
)
ORDER BY u.d_date DESC, u.total_return_amount DESC
LIMIT 100
