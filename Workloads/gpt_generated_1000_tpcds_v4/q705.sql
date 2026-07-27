WITH filtered_items AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_color,
           i.i_formulation,
           i.i_item_desc
    FROM item i
    WHERE regexp_like(i.i_color, '^t')
      AND i.i_formulation LIKE '%goldenrod%'
)
SELECT cp.cp_department,
       cp.cp_catalog_number,
       i.i_item_id,
       i.i_color,
       i.i_formulation,
       SUM(cs.cs_net_profit) AS total_net_profit,
       COUNT(DISTINCT cs.cs_order_number) AS orders,
       CONCAT('Dept ', cp.cp_department, ' - ', cp.cp_type) AS dept_type_label,
       (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS avg_net_profit_all
FROM filtered_items i
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_type LIKE 'AIR%'
GROUP BY cp.cp_department,
         cp.cp_catalog_number,
         i.i_item_id,
         i.i_color,
         i.i_formulation,
         cp.cp_type
HAVING SUM(cs.cs_net_profit) > (SELECT AVG(cs3.cs_net_profit) FROM catalog_sales cs3)
ORDER BY total_net_profit DESC
LIMIT 100
