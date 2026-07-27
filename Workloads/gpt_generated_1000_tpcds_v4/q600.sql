WITH base AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_county,
        cs.cs_net_paid,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand,
        ss.ss_net_profit,
        cs.cs_quantity,
        cr.cr_return_tax
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_current_hdemo_sk IN (3446, 6693, 7006)
      AND w.w_county = 'Walker County'
      AND cp.cp_type = 'A'
      AND cs.cs_quantity > 5
      AND cr.cr_return_tax > 10.0
      AND inv.inv_quantity_on_hand < 100
),
agg AS (
    SELECT
        w_warehouse_id,
        w_city,
        w_county,
        SUM(cs_net_paid) AS total_sales,
        SUM(cr_return_amount) AS total_returns,
        SUM(inv_quantity_on_hand) AS total_inventory_qty,
        AVG(ss_net_profit) AS avg_store_profit
    FROM base
    GROUP BY w_warehouse_id, w_city, w_county
)
SELECT
    w_warehouse_id,
    w_city,
    w_county,
    total_sales,
    total_returns,
    total_inventory_qty,
    avg_store_profit
FROM agg
WHERE total_sales > 10000
  AND total_returns < 5000
  AND avg_store_profit > 0
ORDER BY total_sales DESC
LIMIT 100
