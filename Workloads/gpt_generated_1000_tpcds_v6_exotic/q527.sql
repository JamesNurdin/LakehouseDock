/*
Goal: Analyze high‑value sales by call center and warehouse, comparing the number of active entities and average sales/quantity for each type. The query joins all seven TPC‑DS tables using the permitted keys, applies multiple filters, aggregates in two CTEs, combines the results with UNION ALL, and then performs a final aggregation with ordering and a LIMIT.
*/
WITH sales_by_cc AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_state,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_qty
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
      AND hd_bill.hd_buy_potential = '1001-5000'
      AND p.p_cost > 1000
    GROUP BY cc.cc_call_center_id, cc.cc_state
),
sales_by_wh AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_qty
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE w.w_city = 'Seattle'
      AND td.t_hour BETWEEN 12 AND 20
      AND hd_ship.hd_vehicle_count >= 1
      AND p.p_discount_active = 'Y'
    GROUP BY w.w_warehouse_id, w.w_city
),
combined AS (
    SELECT
        cc_call_center_id AS entity_id,
        'call_center' AS entity_type,
        total_sales,
        total_qty
    FROM sales_by_cc
    WHERE total_sales > 50000
    UNION ALL
    SELECT
        w_warehouse_id AS entity_id,
        'warehouse' AS entity_type,
        total_sales,
        total_qty
    FROM sales_by_wh
    WHERE total_sales > 50000
)
SELECT
    entity_type,
    COUNT(*) AS num_entities,
    SUM(total_sales) AS sum_sales,
    AVG(total_sales) AS avg_sales,
    SUM(total_qty) AS sum_qty,
    AVG(total_qty) AS avg_qty
FROM combined
GROUP BY entity_type
ORDER BY sum_sales DESC
LIMIT 100
