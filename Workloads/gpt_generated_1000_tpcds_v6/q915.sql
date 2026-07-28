WITH filtered_items AS (
    SELECT i_item_sk,
           i_item_desc,
           i_formulation,
           i_units
    FROM item
    WHERE regexp_like(i_formulation, '^[0-9]+[a-z]+[0-9]+$')
)
SELECT
    w.w_warehouse_name,
    sm.sm_code,
    concat(w.w_warehouse_name, ' - ', sm.sm_code) AS warehouse_ship,
    sum(cs.cs_net_paid) AS total_net_paid,
    count(DISTINCT cs.cs_order_number) AS distinct_orders,
    avg(cs.cs_net_profit) AS avg_net_profit,
    (SELECT avg(cs2.cs_net_profit) FROM catalog_sales cs2) AS overall_avg_profit,
    regexp_extract(fi.i_formulation, '(\\d+)$') AS formulation_suffix
FROM catalog_sales cs
JOIN filtered_items fi ON cs.cs_item_sk = fi.i_item_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE sm.sm_code LIKE 'A%'
  AND td.t_hour BETWEEN 8 AND 17
  AND fi.i_units LIKE '%Bundle%'
GROUP BY
    w.w_warehouse_name,
    sm.sm_code,
    concat(w.w_warehouse_name, ' - ', sm.sm_code),
    fi.i_formulation
HAVING avg(cs.cs_net_profit) > (SELECT avg(cs3.cs_net_profit) FROM catalog_sales cs3)
ORDER BY total_net_paid DESC
LIMIT 100
