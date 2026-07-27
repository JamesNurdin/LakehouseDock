WITH filtered_warehouses AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_name,
        w_city,
        w_state,
        concat(w_city, ', ', w_state) AS location
    FROM warehouse
    WHERE regexp_like(w_warehouse_name, '^A.*')
)
SELECT
    fw.location,
    regexp_extract(fw.w_warehouse_name, '([A-Za-z]+)') AS name_prefix,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_net_paid_inc_tax) AS avg_net_paid_inc_tax
FROM filtered_warehouses fw
JOIN catalog_sales cs
    ON cs.cs_warehouse_sk = fw.w_warehouse_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_buy_potential LIKE '%HIGH%'
  AND hd.hd_vehicle_count >= 1
GROUP BY fw.location, fw.w_warehouse_name
ORDER BY total_net_profit DESC
LIMIT 10
