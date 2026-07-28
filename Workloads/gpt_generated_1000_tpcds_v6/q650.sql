WITH
    -- Aggregate catalog sales with all required dimensions
    catalog_agg AS (
        SELECT
            i.i_item_id,
            i.i_category,
            w.w_warehouse_id,
            w.w_city,
            SUM(cs.cs_net_profit)            AS catalog_profit,
            SUM(cs.cs_quantity)               AS catalog_quantity,
            COUNT(*)                          AS catalog_orders
        FROM catalog_sales cs
        JOIN item i                     ON cs.cs_item_sk      = i.i_item_sk
        JOIN warehouse w                ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p                ON cs.cs_promo_sk    = p.p_promo_sk
        JOIN time_dim td                ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN catalog_page cp            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN call_center cc             ON cs.cs_call_center_sk   = cc.cc_call_center_sk
        JOIN ship_mode sm               ON cs.cs_ship_mode_sk    = sm.sm_ship_mode_sk
        JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
        JOIN customer_address ca_bill       ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship       ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
        JOIN inventory inv                 ON inv.inv_item_sk     = i.i_item_sk
                                         AND inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE
            td.t_hour BETWEEN 8 AND 20                             -- business hours
            AND i.i_size IN ('small', 'petite')                     -- specific product sizes
            AND w.w_warehouse_sq_ft > 600000                       -- large warehouses only
            AND p.p_discount_active = 'Y'                          -- active promotions
            AND hd_bill.hd_vehicle_count >= 2                      -- households with at least 2 vehicles
        GROUP BY
            i.i_item_id,
            i.i_category,
            w.w_warehouse_id,
            w.w_city
    ),
    -- Aggregate web sales with all required dimensions
    web_agg AS (
        SELECT
            i.i_item_id,
            i.i_category,
            w.w_warehouse_id,
            w.w_city,
            SUM(ws.ws_net_profit)            AS web_profit,
            SUM(ws.ws_quantity)               AS web_quantity,
            COUNT(*)                          AS web_orders
        FROM web_sales ws
        JOIN item i                     ON ws.ws_item_sk      = i.i_item_sk
        JOIN warehouse w                ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p                ON ws.ws_promo_sk    = p.p_promo_sk
        JOIN time_dim td                ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN web_page wp                ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN ship_mode sm               ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
        JOIN customer_address ca_bill       ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship       ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
        JOIN inventory inv                 ON inv.inv_item_sk     = i.i_item_sk
                                         AND inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE
            td.t_hour BETWEEN 8 AND 20
            AND i.i_size IN ('small', 'petite')
            AND w.w_warehouse_sq_ft > 600000
            AND p.p_discount_active = 'Y'
            AND hd_bill.hd_vehicle_count >= 2
        GROUP BY
            i.i_item_id,
            i.i_category,
            w.w_warehouse_id,
            w.w_city
    ),
    -- Combine catalog and web aggregates
    combined AS (
        SELECT
            ca.i_item_id,
            ca.i_category,
            ca.w_warehouse_id,
            ca.w_city,
            COALESCE(ca.catalog_profit, 0) + COALESCE(wa.web_profit, 0)         AS total_profit,
            COALESCE(ca.catalog_quantity, 0) + COALESCE(wa.web_quantity, 0)     AS total_quantity,
            COALESCE(ca.catalog_orders, 0) + COALESCE(wa.web_orders, 0)         AS total_orders
        FROM catalog_agg ca
        FULL OUTER JOIN web_agg wa
            ON ca.i_item_id     = wa.i_item_id
           AND ca.i_category    = wa.i_category
           AND ca.w_warehouse_id = wa.w_warehouse_id
           AND ca.w_city        = wa.w_city
    )
SELECT
    i_item_id,
    i_category,
    w_warehouse_id,
    w_city,
    total_profit,
    total_quantity,
    total_orders,
    ROW_NUMBER() OVER (PARTITION BY w_warehouse_id ORDER BY total_profit DESC) AS profit_rank
FROM combined
ORDER BY profit_rank, total_profit DESC
LIMIT 100
