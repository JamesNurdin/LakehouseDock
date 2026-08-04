WITH inventory_agg AS (
    SELECT
        w.w_warehouse_sk,
        d.d_year,
        SUM(i.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY w.w_warehouse_sk, d.d_year
)
SELECT
    year,
    SUM(total_profit) AS combined_profit,
    AVG(total_inventory_qty) AS avg_inventory_qty
FROM (
    SELECT
        d.d_year AS year,
        sm.sm_type,
        p.p_promo_name,
        SUM(cs.cs_net_profit) AS total_profit,
        inv_agg.total_qty_on_hand AS total_inventory_qty
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN inventory_agg inv_agg ON inv_agg.w_warehouse_sk = w.w_warehouse_sk AND inv_agg.d_year = d.d_year
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
      AND t.t_shift = 'second'
      AND sm.sm_type = 'AIR'
      AND p.p_discount_active = 'Y'
      AND ca_bill.ca_state = 'CA'
      AND cp.cp_department = 'Electronics'
    GROUP BY d.d_year, sm.sm_type, p.p_promo_name, inv_agg.total_qty_on_hand

    UNION

    SELECT
        d2.d_year AS year,
        sm2.sm_type,
        p2.p_promo_name,
        SUM(ws.ws_net_profit) AS total_profit,
        inv_agg2.total_qty_on_hand AS total_inventory_qty
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    JOIN customer_address ca_bill2 ON ws.ws_bill_addr_sk = ca_bill2.ca_address_sk
    JOIN customer_address ca_ship2 ON ws.ws_ship_addr_sk = ca_ship2.ca_address_sk
    LEFT JOIN inventory_agg inv_agg2 ON inv_agg2.w_warehouse_sk = w2.w_warehouse_sk AND inv_agg2.d_year = d2.d_year
    JOIN store s2 ON s2.s_closed_date_sk = d2.d_date_sk
    WHERE d2.d_year = 1999
      AND t2.t_shift = 'second'
      AND sm2.sm_type = 'AIR'
      AND p2.p_discount_active = 'Y'
      AND ca_bill2.ca_state = 'CA'
      AND wp.wp_type = 'home'
    GROUP BY d2.d_year, sm2.sm_type, p2.p_promo_name, inv_agg2.total_qty_on_hand
) AS union_all
GROUP BY year
ORDER BY year DESC
