WITH ss_agg AS (
    SELECT
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets
    FROM store_sales
    WHERE ss_quantity > 20
      AND ss_sales_price >= 10.00
      AND ss_wholesale_cost < 80.00
    GROUP BY ss_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    cp.cp_catalog_page_id,
    cp.cp_description,
    sm.sm_type,
    w.w_warehouse_name,
    ss_agg.total_quantity,
    ss_agg.avg_sales_price,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    CASE
        WHEN SUM(cs.cs_ext_sales_price) > 50000 THEN 'High'
        WHEN SUM(cs.cs_ext_sales_price) > 20000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_volume_category,
    MIN(cs.cs_net_profit) AS min_net_profit,
    MAX(cs.cs_net_profit) AS max_net_profit
FROM ss_agg
JOIN item i ON ss_agg.ss_item_sk = i.i_item_sk
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE cp.cp_department = 'Books'
  AND cp.cp_type = 'Catalog'
  AND cp.cp_end_date_sk BETWEEN 2450990 AND 2451300
  AND sm.sm_type = 'AIR'
  AND w.w_state = 'CA'
  AND i.i_brand = 'Brand#12'
GROUP BY
    i.i_item_id,
    i.i_product_name,
    cp.cp_catalog_page_id,
    cp.cp_description,
    sm.sm_type,
    w.w_warehouse_name,
    ss_agg.total_quantity,
    ss_agg.avg_sales_price
ORDER BY catalog_sales_total DESC
LIMIT 100
