WITH sales_cte AS (
    SELECT 
        cc.cc_call_center_id AS call_center_id,
        cc.cc_name AS call_center_name,
        cc.cc_company_name AS company_name,
        'sales' AS metric_type,
        SUM(cs.cs_net_paid) AS total_amount,
        SUM(cs.cs_quantity) AS total_quantity,
        (
            SELECT MAX(cs2.cs_coupon_amt)
            FROM tpcds.catalog_sales cs2
            WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk
        ) AS max_coupon_amt,
        CAST(NULL AS decimal(7,2)) AS min_return_fee
    FROM tpcds.call_center cc
    JOIN tpcds.catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_ext_wholesale_cost > 1000
      AND w.w_warehouse_sq_ft > 600000
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY cc.cc_call_center_id, cc.cc_name, cc.cc_company_name, cc.cc_call_center_sk
),
returns_cte AS (
    SELECT 
        cc.cc_call_center_id AS call_center_id,
        cc.cc_name AS call_center_name,
        cc.cc_company_name AS company_name,
        'returns' AS metric_type,
        SUM(cr.cr_return_amount) AS total_amount,
        SUM(cr.cr_return_quantity) AS total_quantity,
        CAST(NULL AS decimal(7,2)) AS max_coupon_amt,
        (
            SELECT MIN(cr2.cr_fee)
            FROM tpcds.catalog_returns cr2
            WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
        ) AS min_return_fee
    FROM tpcds.call_center cc
    JOIN tpcds.catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_quantity > 0
      AND w.w_city = 'Greenwood'
      AND NOT EXISTS (
            SELECT 1
            FROM tpcds.catalog_sales cs2
            WHERE cs2.cs_order_number = cr.cr_order_number
              AND cs2.cs_coupon_amt > 4000
        )
    GROUP BY cc.cc_call_center_id, cc.cc_name, cc.cc_company_name, cc.cc_call_center_sk
)
SELECT 
    combined.call_center_id,
    combined.call_center_name,
    combined.company_name,
    combined.metric_type,
    combined.total_amount,
    combined.total_quantity,
    combined.max_coupon_amt,
    combined.min_return_fee
FROM (
    SELECT 
        call_center_id,
        call_center_name,
        company_name,
        metric_type,
        total_amount,
        total_quantity,
        max_coupon_amt,
        min_return_fee
    FROM sales_cte
    UNION ALL
    SELECT 
        call_center_id,
        call_center_name,
        company_name,
        metric_type,
        total_amount,
        total_quantity,
        max_coupon_amt,
        min_return_fee
    FROM returns_cte
) AS combined
ORDER BY combined.total_amount DESC
LIMIT 100
