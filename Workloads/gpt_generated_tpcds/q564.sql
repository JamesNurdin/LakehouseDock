WITH sales_agg AS (
    SELECT w2.w_warehouse_sk AS w_warehouse_sk,
           sum(cs.cs_ext_sales_price) AS total_sales_amount,
           sum(cs.cs_net_profit) AS total_sales_profit
    FROM catalog_sales cs
    JOIN warehouse w2
      ON cs.cs_warehouse_sk = w2.w_warehouse_sk
    GROUP BY w2.w_warehouse_sk
),
returns_agg AS (
    SELECT w3.w_warehouse_sk AS w_warehouse_sk,
           sum(cr.cr_return_amount) AS total_return_amount,
           sum(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN warehouse w3
      ON cs.cs_warehouse_sk = w3.w_warehouse_sk
    GROUP BY w3.w_warehouse_sk
),
inventory_agg AS (
    SELECT w4.w_warehouse_sk AS w_warehouse_sk,
           sum(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory inv
    JOIN warehouse w4
      ON inv.inv_warehouse_sk = w4.w_warehouse_sk
    GROUP BY w4.w_warehouse_sk
)
SELECT w.w_warehouse_id,
       w.w_warehouse_name,
       w.w_state,
       coalesce(s.total_sales_amount, 0) AS total_sales_amount,
       coalesce(s.total_sales_profit, 0) AS total_sales_profit,
       coalesce(r.total_return_amount, 0) AS total_return_amount,
       coalesce(r.total_return_loss, 0) AS total_return_loss,
       coalesce(i.total_inventory_qty, 0) AS total_inventory_qty,
       (coalesce(s.total_sales_profit, 0) - coalesce(r.total_return_loss, 0)) AS net_effect
FROM warehouse w
LEFT JOIN sales_agg s
  ON w.w_warehouse_sk = s.w_warehouse_sk
LEFT JOIN returns_agg r
  ON w.w_warehouse_sk = r.w_warehouse_sk
LEFT JOIN inventory_agg i
  ON w.w_warehouse_sk = i.w_warehouse_sk
ORDER BY net_effect DESC
LIMIT 10
