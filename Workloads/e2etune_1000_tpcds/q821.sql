WITH sales_filtered AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        cs.cs_ship_mode_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_tax > 0
      AND cs.cs_ship_mode_sk IN (2, 3, 8)
      AND cs.cs_list_price > 50
),
inventory_agg AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk
)
SELECT
    w.w_city AS warehouse_city,
    i.i_category AS product_category,
    SUM(s.cs_net_profit) AS total_net_profit,
    SUM(s.cs_ext_sales_price) AS total_sales,
    AVG(s.cs_ext_discount_amt) AS avg_discount,
    SUM(s.cs_quantity) AS total_quantity_sold,
    COALESCE(SUM(ia.total_inventory_on_hand), 0) AS total_inventory_on_hand,
    CASE WHEN COALESCE(SUM(ia.total_inventory_on_hand), 0) = 0 THEN NULL
         ELSE SUM(s.cs_net_profit) / SUM(ia.total_inventory_on_hand) END AS profit_per_inventory,
    RANK() OVER (PARTITION BY w.w_city ORDER BY SUM(s.cs_net_profit) DESC) AS category_rank
FROM sales_filtered s
JOIN household_demographics hd ON s.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON s.cs_bill_addr_sk = ca.ca_address_sk
JOIN item i ON s.cs_item_sk = i.i_item_sk
JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory_agg ia ON ia.inv_item_sk = i.i_item_sk AND ia.inv_warehouse_sk = w.w_warehouse_sk
WHERE hd.hd_buy_potential = 'High'
  AND hd.hd_income_band_sk >= 5
  AND ca.ca_country = 'United States'
GROUP BY w.w_city, i.i_category
HAVING SUM(s.cs_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 10
