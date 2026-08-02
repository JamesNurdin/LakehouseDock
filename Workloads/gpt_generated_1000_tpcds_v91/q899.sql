WITH sales_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_paid_inc_ship,
        cs.cs_sold_date_sk,
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        p.p_discount_active,
        cc.cc_name AS call_center_name,
        cp.cp_catalog_page_number,
        sm.sm_type,
        w.w_warehouse_name,
        w.w_state,
        t.t_hour,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        CASE WHEN cs.cs_quantity > 10 THEN 'LARGE' ELSE 'SMALL' END AS quantity_group
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN item i_alt ON cs.cs_item_sk = i_alt.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN warehouse w_stock ON cs.cs_warehouse_sk = w_stock.w_warehouse_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450836 AND 2451074
)
SELECT
    sb.quantity_group,
    COUNT(DISTINCT sb.cs_order_number) AS num_orders,
    SUM(sb.cs_net_paid) AS total_net_paid,
    AVG(sb.cs_quantity) AS avg_quantity,
    MIN(sb.cs_net_paid_inc_ship) AS min_net_paid_inc_ship,
    MAX(sb.cs_net_paid_inc_ship) AS max_net_paid_inc_ship
FROM sales_base sb
WHERE sb.cs_order_number IN (
    SELECT cs_order_number
    FROM sales_base
    WHERE quantity_group = 'LARGE' AND w_state = 'CA'
    INTERSECT
    SELECT cs_order_number
    FROM sales_base
    WHERE p_discount_active = 'Y' AND i_category = 'Sports'
)
GROUP BY sb.quantity_group
ORDER BY total_net_paid DESC
LIMIT 100
