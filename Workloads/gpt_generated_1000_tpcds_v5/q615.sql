WITH sales_ship AS (
    SELECT
        cs.cs_warehouse_sk AS warehouse_sk,
        cs.cs_ship_mode_sk AS ship_mode_sk,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        sm.sm_type,
        sm.sm_carrier,
        w.w_warehouse_name,
        w.w_zip,
        substr(w.w_zip, 1, 3) AS zip_prefix,
        concat(w.w_warehouse_name, ' - ', sm.sm_carrier) AS wh_carrier
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(sm.sm_type, '^AIR.*')
      AND w.w_country LIKE 'U%'
),
inventory_by_wh AS (
    SELECT
        inv.inv_warehouse_sk AS warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand,
        regexp_extract(w.w_zip, '(\\d{3})', 1) AS zip_prefix_extracted
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY inv.inv_warehouse_sk, regexp_extract(w.w_zip, '(\\d{3})', 1)
)
SELECT
    ss.wh_carrier,
    ss.zip_prefix,
    i.total_on_hand,
    SUM(ss.cs_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
FROM sales_ship ss
JOIN inventory_by_wh i
  ON ss.warehouse_sk = i.warehouse_sk
  AND ss.zip_prefix = i.zip_prefix_extracted
WHERE i.total_on_hand > 500
GROUP BY ss.wh_carrier, ss.zip_prefix, i.total_on_hand
HAVING SUM(ss.cs_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
