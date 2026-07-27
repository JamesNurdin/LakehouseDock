WITH returns_agg AS (
    SELECT
        cr_order_number,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_qty,
        MAX(cr_return_ship_cost) AS max_ship_cost
    FROM catalog_returns
    WHERE cr_return_amount > 100
      AND cr_return_quantity > 1
    GROUP BY cr_order_number
    HAVING SUM(cr_return_amount) > 500
)
SELECT
    c.c_customer_id,
    i.i_product_name,
    ra.total_return_amount,
    cs.cs_net_paid,
    ss.ss_net_profit,
    w.w_warehouse_name,
    COALESCE(sm.sm_type, 'UNKNOWN') AS ship_type,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY ra.total_return_amount DESC) AS warehouse_return_rank,
    ROW_NUMBER() OVER (ORDER BY ra.total_return_amount DESC) AS overall_rank
FROM returns_agg ra
JOIN catalog_sales cs
    ON ra.cr_order_number = cs.cs_order_number
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_customer_sk = c.c_customer_sk
WHERE cs.cs_sales_price > 20
  AND ss.ss_quantity > 2
  AND w.w_state = 'CA'
  AND i.i_category_id = 5
ORDER BY ra.total_return_amount DESC
LIMIT 100
