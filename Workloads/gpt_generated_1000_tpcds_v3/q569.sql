WITH sales_agg AS (
    SELECT
        store.s_store_id,
        store.s_store_name,
        date_dim.d_date,
        warehouse.w_warehouse_sk,
        warehouse.w_warehouse_name,
        SUM(store_sales.ss_net_paid) AS total_net_paid,
        SUM(store_sales.ss_net_profit) AS total_net_profit,
        AVG(inventory.inv_quantity_on_hand) AS avg_inventory_qty
    FROM store_sales
    JOIN date_dim
        ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    JOIN store
        ON store_sales.ss_store_sk = store.s_store_sk
    JOIN inventory
        ON inventory.inv_date_sk = date_dim.d_date_sk
    JOIN warehouse
        ON inventory.inv_warehouse_sk = warehouse.w_warehouse_sk
    WHERE
        date_dim.d_holiday = 'N'
        AND date_dim.d_weekend = 'N'
        AND inventory.inv_quantity_on_hand > 0
        AND store_sales.ss_net_profit > 0
    GROUP BY
        store.s_store_id,
        store.s_store_name,
        date_dim.d_date,
        warehouse.w_warehouse_sk,
        warehouse.w_warehouse_name
)
SELECT
    s_store_id,
    s_store_name,
    d_date,
    w_warehouse_name,
    total_net_paid,
    total_net_profit,
    avg_inventory_qty,
    (SELECT MAX(inv_quantity_on_hand)
        FROM inventory inv_sub
        WHERE inv_sub.inv_warehouse_sk = sales_agg.w_warehouse_sk) AS max_qty_in_warehouse,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_net_paid DESC) AS sales_rank_by_store,
    RANK() OVER (ORDER BY total_net_paid DESC) AS overall_sales_rank
FROM sales_agg
ORDER BY total_net_paid DESC, s_store_id
LIMIT 100
