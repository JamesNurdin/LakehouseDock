/*
Goal: Identify catalog sales orders that occurred in New York warehouses and have not been returned, then compute a running total of sales price per state.
The query uses an EXCEPT set operation to subtract returned order numbers from sold order numbers, joins the result back to the sales fact to retrieve amounts, and applies a windowed SUM.
*/
WITH sales_keys AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'NY'
      AND cs.cs_ext_sales_price > 1000
),
returns_keys AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'NY'
),
new_orders AS (
    SELECT cs_order_number
    FROM sales_keys
    EXCEPT
    SELECT cr_order_number
    FROM returns_keys
)
SELECT
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    w.w_state,
    SUM(cs.cs_ext_sales_price) OVER (
        PARTITION BY w.w_state
        ORDER BY cs.cs_order_number
        ROWS UNBOUNDED PRECEDING
    ) AS running_total_sales
FROM catalog_sales cs
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN new_orders no ON cs.cs_order_number = no.cs_order_number
WHERE w.w_state = 'NY'
ORDER BY w.w_state, cs.cs_order_number
