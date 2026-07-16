WITH item_inventory AS (
    SELECT i.i_item_sk,
           SUM(inv.inv_quantity_on_hand) AS total_inventory,
           MAX(i.i_current_price) AS current_price,
           MAX(i.i_wholesale_cost) AS wholesale_cost
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_quantity_on_hand > 0
    GROUP BY i.i_item_sk
)
SELECT
    cc.cc_state,
    cc.cc_class,
    cc.cc_manager,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(ii.current_price) AS avg_item_price,
    SUM(ii.total_inventory) AS total_inventory,
    ROUND(SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0), 4) AS profit_margin,
    RANK() OVER (PARTITION BY cc.cc_state ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank_state
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item_inventory ii ON cs.cs_item_sk = ii.i_item_sk
WHERE cc.cc_state IN ('TN', 'GA', 'MI')
  AND cc.cc_class = 'large'
  AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
  AND ii.total_inventory > 5000
GROUP BY cc.cc_state, cc.cc_class, cc.cc_manager
HAVING SUM(cs.cs_net_paid) > 100000
ORDER BY total_net_profit DESC
LIMIT 10
