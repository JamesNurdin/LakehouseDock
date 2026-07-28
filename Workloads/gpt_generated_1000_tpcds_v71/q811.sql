WITH catalog_city_sales AS (
    SELECT
        cc.cc_city AS city,
        CAST(SUM(cs.cs_net_paid) AS double) AS total_amount,
        'catalog' AS source
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_ext_tax > 20.00
      AND cc.cc_state = 'CA'
    GROUP BY cc.cc_city
), inventory_city_stock AS (
    SELECT
        w.w_city AS city,
        CAST(SUM(inv.inv_quantity_on_hand) AS double) AS total_amount,
        'inventory' AS source
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'TX'
    GROUP BY w.w_city
)
SELECT city,
       total_amount,
       source
FROM (
    SELECT city, total_amount, source FROM catalog_city_sales
    UNION ALL
    SELECT city, total_amount, source FROM inventory_city_stock
) combined
ORDER BY total_amount DESC
LIMIT 100
