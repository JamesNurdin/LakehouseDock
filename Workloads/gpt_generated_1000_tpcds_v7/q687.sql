WITH profit_by_year AS (
    SELECT d.d_year AS year,
           SUM(cs.cs_net_profit) AS metric_value,
           'Net Profit' AS metric_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY d.d_year
    HAVING SUM(cs.cs_net_profit) > (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2)
),
inventory_by_year AS (
    SELECT d.d_year AS year,
           SUM(i.inv_quantity_on_hand) AS metric_value,
           'Inventory Quantity' AS metric_name
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_warehouse_sq_ft > 500000
    GROUP BY d.d_year
)
SELECT metric_name,
       year,
       metric_value
FROM profit_by_year
UNION ALL
SELECT metric_name,
       year,
       metric_value
FROM inventory_by_year
ORDER BY metric_name, year
