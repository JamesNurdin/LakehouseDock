WITH sales_cte AS (
    SELECT cs.cs_order_number AS order_number,
           CASE
               WHEN cs.cs_net_profit > 1000 THEN 'HIGH'
               WHEN cs.cs_net_profit > 0 THEN 'MEDIUM'
               ELSE 'LOW'
           END AS profit_category
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cc.cc_state = 'CA'
      AND w.w_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
),
returns_cte AS (
    SELECT cr.cr_order_number AS order_number,
           CASE
               WHEN cr.cr_net_loss > 500 THEN 'HIGH'
               WHEN cr.cr_net_loss > 0 THEN 'MEDIUM'
               ELSE 'LOW'
           END AS profit_category
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cc.cc_state = 'CA'
      AND w.w_state = 'CA'
      AND r.r_reason_desc LIKE '%defect%'
      AND td.t_hour BETWEEN 9 AND 17
)
SELECT order_number, profit_category
FROM sales_cte
INTERSECT
SELECT order_number, profit_category
FROM returns_cte
ORDER BY order_number
