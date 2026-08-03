/* goal: Identify top‑selling items by net profit per warehouse in California, compare sales with inventory levels, flag profit vs loss, count items sold but missing from inventory, and retain all warehouses even when they have no sales. */
WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        t.t_hour,
        t.t_am_pm,
        cc.cc_company,
        w.w_warehouse_name,
        w.w_state,
        i.i_brand,
        i.i_category
    FROM catalog_sales cs
    RIGHT OUTER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE w.w_state = 'CA'
      AND cc.cc_company = 1
      AND t.t_hour = 12
)
SELECT
    b.w_warehouse_name,
    b.w_state,
    b.i_brand,
    b.i_category,
    b.cs_order_number,
    b.cs_quantity,
    b.cs_net_profit,
    CASE WHEN b.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    (
        SELECT COALESCE(SUM(inv2.inv_quantity_on_hand), 0)
        FROM inventory inv2
        WHERE inv2.inv_item_sk = b.cs_item_sk
          AND inv2.inv_warehouse_sk = b.cs_warehouse_sk
    ) AS total_inventory_qty,
    ROW_NUMBER() OVER (PARTITION BY b.w_warehouse_name ORDER BY b.cs_net_profit DESC) AS profit_rank,
    (
        SELECT COUNT(*)
        FROM (
            SELECT cs_item_sk FROM catalog_sales
            EXCEPT
            SELECT inv_item_sk FROM inventory
        ) diff
    ) AS missing_item_cnt
FROM base b
LEFT JOIN catalog_returns cr
    ON b.cs_order_number = cr.cr_order_number
   AND b.cs_item_sk = cr.cr_item_sk
LEFT JOIN inventory inv
    ON inv.inv_item_sk = b.cs_item_sk
   AND inv.inv_warehouse_sk = b.cs_warehouse_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = b.cs_order_number
      AND cr2.cr_return_amount > 0
)
GROUP BY
    b.w_warehouse_name,
    b.w_state,
    b.i_brand,
    b.i_category,
    b.cs_order_number,
    b.cs_quantity,
    b.cs_net_profit,
    b.cs_sold_date_sk,
    b.cs_sold_time_sk,
    b.cs_call_center_sk,
    b.cs_warehouse_sk,
    b.cs_item_sk,
    b.cs_net_paid,
    b.cs_ext_sales_price,
    b.t_hour,
    b.t_am_pm,
    b.cc_company
ORDER BY profit_rank, b.w_warehouse_name
LIMIT 100
