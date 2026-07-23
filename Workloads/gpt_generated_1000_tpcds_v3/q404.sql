WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand,
        AVG(inv_quantity_on_hand) AS avg_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 300
      AND inv_warehouse_sk IN (2, 6, 15, 20)
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_class,
    i.i_brand,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_ext_discount_amt,
    cs.cs_net_profit,
    cs.cs_net_paid_inc_tax,
    ia.total_quantity_on_hand,
    CASE
        WHEN cs.cs_ext_discount_amt > 1000 THEN 'High'
        WHEN cs.cs_ext_discount_amt > 500 THEN 'Medium'
        ELSE 'Low'
    END AS discount_level,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i.i_item_sk
    ) AS avg_item_profit,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY cs.cs_net_profit DESC) AS profit_rank_in_category,
    RANK() OVER (ORDER BY cs.cs_net_profit DESC) AS overall_profit_rank
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN inv_agg ia ON ia.inv_item_sk = i.i_item_sk
WHERE cs.cs_ext_ship_cost > 500
  AND cs.cs_coupon_amt < 500
  AND cs.cs_net_paid_inc_tax BETWEEN 100 AND 600
  AND i.i_class IN ('furniture', 'accessories')
  AND cs.cs_quantity > 1
ORDER BY overall_profit_rank ASC
LIMIT 100
