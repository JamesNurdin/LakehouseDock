WITH per_item_warehouse AS (
    SELECT
        i.i_item_id AS item_id,
        w.w_warehouse_id AS warehouse_id,
        w.w_warehouse_name AS warehouse_name,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    WHERE cs.cs_wholesale_cost BETWEEN 20 AND 80
      AND inv.inv_warehouse_sk IN (13, 6, 15)
      AND inv.inv_quantity_on_hand > 0
      AND ss.ss_ext_tax > 30
      AND i.i_brand = 'BrandX'
      AND cs.cs_sold_date_sk BETWEEN 2450820 AND 2450900
    GROUP BY ROLLUP (i.i_item_id, w.w_warehouse_id, w.w_warehouse_name)
)
SELECT
    item_id,
    warehouse_id,
    warehouse_name,
    total_profit,
    CASE
        WHEN total_profit >= 50000 THEN 'High'
        WHEN total_profit >= 20000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    AVG(total_profit) OVER (PARTITION BY warehouse_id) AS avg_profit_per_warehouse,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM per_item_warehouse
WHERE total_catalog_sales > 10000
  AND total_store_sales > 5000
  AND total_profit IS NOT NULL
ORDER BY warehouse_id, profit_rank
