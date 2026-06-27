WITH sales_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        sum(cs.cs_ext_sales_price) AS total_sales,
        sum(cs.cs_quantity) AS total_quantity_sold,
        sum(cs.cs_ext_discount_amt) AS total_discount_amount,
        sum(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
),
inventory_agg AS (
    SELECT
        w.w_warehouse_sk,
        sum(inv.inv_quantity_on_hand) AS total_inventory_quantity
    FROM inventory inv
    JOIN warehouse w
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk
)
SELECT
    s.w_warehouse_name,
    s.total_sales,
    s.total_quantity_sold,
    s.total_discount_amount,
    s.total_net_profit,
    i.total_inventory_quantity,
    CASE
        WHEN i.total_inventory_quantity = 0 THEN NULL
        ELSE s.total_sales / i.total_inventory_quantity
    END AS sales_per_inventory_unit,
    CASE
        WHEN s.total_sales = 0 THEN NULL
        ELSE s.total_net_profit / s.total_sales
    END AS net_profit_margin,
    CASE
        WHEN i.total_inventory_quantity = 0 THEN NULL
        ELSE s.total_quantity_sold / i.total_inventory_quantity
    END AS inventory_turnover_ratio
FROM sales_agg s
JOIN inventory_agg i
  ON s.w_warehouse_sk = i.w_warehouse_sk
ORDER BY s.total_sales DESC
