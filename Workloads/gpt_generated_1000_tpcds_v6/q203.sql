/*
Goal: Identify high‑performing warehouses in California by aggregating catalog return amounts,
return quantities, reversed charges and inventory stock, then rank them by total return amount.
The query joins the fact table catalog_returns with warehouse and inventory, applies several filters,
uses a CTE for the first level of aggregation, applies a second‑level filter on the average return amount,
adds a window function to rank the warehouses, orders the result, and limits it to the top 100 rows.
*/
WITH warehouse_returns AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(cr.cr_return_amount)               AS total_return_amount,
        SUM(cr.cr_return_quantity)             AS total_return_qty,
        AVG(cr.cr_reversed_charge)             AS avg_reversed_charge,
        COUNT(DISTINCT cr.cr_order_number)     AS distinct_orders,
        SUM(inv.inv_quantity_on_hand)          AS total_inventory_qty
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2459999
      AND cr.cr_return_quantity > 1
      AND cr.cr_return_amount > 50
      AND w.w_state = 'CA'
      AND inv.inv_quantity_on_hand > 500
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
)
SELECT
    wr.w_warehouse_sk,
    wr.w_warehouse_name,
    wr.total_return_amount,
    wr.total_return_qty,
    wr.avg_reversed_charge,
    wr.distinct_orders,
    wr.total_inventory_qty,
    ROW_NUMBER() OVER (ORDER BY wr.total_return_amount DESC) AS revenue_rank
FROM warehouse_returns wr
WHERE wr.total_return_amount > (
        SELECT AVG(total_return_amount) FROM warehouse_returns
    )
ORDER BY wr.total_return_amount DESC
LIMIT 100
