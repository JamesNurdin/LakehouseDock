WITH filtered_warehouses AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_suite_number,
        w.w_street_type,
        w.w_city,
        w.w_state,
        CONCAT(w.w_city, ', ', w.w_state) AS location,
        regexp_extract(w.w_warehouse_name, '^(\\w+)', 1) AS name_prefix
    FROM warehouse w
    WHERE regexp_like(w.w_suite_number, '^Suite [A-Z]$')
      AND w.w_street_type LIKE '%Ave%'
)
SELECT
    fw.w_warehouse_sk,
    fw.location,
    fw.name_prefix,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cr.cr_net_loss) AS total_return_loss
FROM filtered_warehouses fw
JOIN catalog_sales cs
    ON cs.cs_warehouse_sk = fw.w_warehouse_sk
JOIN catalog_returns cr
    ON cr.cr_warehouse_sk = fw.w_warehouse_sk
   AND cr.cr_order_number = cs.cs_order_number
WHERE cs.cs_net_paid_inc_tax > 1000
  AND EXISTS (
        SELECT 1
        FROM customer c
        WHERE c.c_customer_sk = cs.cs_bill_customer_sk
          AND c.c_email_address LIKE '%@example.com'
    )
GROUP BY GROUPING SETS (
    (fw.w_warehouse_sk, fw.location, fw.name_prefix),
    ()
)
ORDER BY fw.w_warehouse_sk ASC, total_net_profit DESC
LIMIT 100
