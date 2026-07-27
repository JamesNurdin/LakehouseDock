WITH profit_per_warehouse AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND cc.cc_state = 'CA'
      AND cs.cs_sales_price > 50
      AND cs.cs_net_profit > (
          SELECT AVG(cs2.cs_net_profit)
          FROM catalog_sales cs2
      )
    GROUP BY w.w_warehouse_id, w.w_city
)

SELECT
    profit.w_warehouse_id AS warehouse_id,
    profit.w_city AS city,
    'profit' AS metric_name,
    CAST(profit.total_profit AS double) AS metric_value
FROM profit_per_warehouse profit

UNION ALL

SELECT
    w.w_warehouse_id AS warehouse_id,
    w.w_city AS city,
    'inventory' AS metric_name,
    CAST(SUM(i.inv_quantity_on_hand) AS double) AS metric_value
FROM inventory i
JOIN warehouse w
    ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.inv_date_sk BETWEEN 2451050 AND 2451060
GROUP BY w.w_warehouse_id, w.w_city

LIMIT 100
