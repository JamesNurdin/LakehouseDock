WITH latest_inventory AS (
    SELECT i.inv_warehouse_sk,
           i.inv_item_sk,
           i.inv_quantity_on_hand
    FROM inventory i
    WHERE i.inv_date_sk = (
        SELECT MAX(i2.inv_date_sk)
        FROM inventory i2
        WHERE i2.inv_warehouse_sk = i.inv_warehouse_sk
    )
),
promo_filtered AS (
    SELECT p.p_promo_sk,
           p.p_promo_id,
           p.p_promo_name,
           regexp_extract(p.p_promo_id, '\\d+', 0) AS promo_number
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, '[0-9]{2,}')
      AND p.p_channel_event = 'Y'
)
SELECT
    w.w_warehouse_id,
    concat('Warehouse ', w.w_warehouse_name) AS full_warehouse_label,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    array_agg(DISTINCT promo_filtered.promo_number) AS promo_numbers,
    SUM(COALESCE(i.inv_quantity_on_hand, 0)) AS total_inventory_on_hand
FROM catalog_sales cs
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promo_filtered
    ON cs.cs_promo_sk = promo_filtered.p_promo_sk
LEFT JOIN latest_inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
   AND i.inv_item_sk = cs.cs_item_sk
WHERE w.w_warehouse_name LIKE '%Warehouse%'
  AND cs.cs_ext_discount_amt > (
        SELECT AVG(cs2.cs_ext_discount_amt)
        FROM catalog_sales cs2
    )
GROUP BY
    w.w_warehouse_id,
    w.w_warehouse_name
ORDER BY total_net_profit DESC
LIMIT 100
