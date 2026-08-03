WITH
    base AS (
        SELECT
            cs.cs_order_number,
            cs.cs_sold_date_sk,
            cs.cs_quantity,
            cs.cs_net_paid,
            cs.cs_net_profit,
            cc.cc_call_center_id,
            cp.cp_department,
            sm.sm_type,
            w.w_warehouse_name,
            i.i_category,
            i.i_brand,
            p.p_promo_name,
            ca.ca_state,
            cr.cr_return_quantity,
            ws.ws_net_paid AS ws_net_paid,
            cs.cs_item_sk
        FROM catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_bill_addr_sk = ca.ca_address_sk
        WHERE cc.cc_employees > 500000
          AND ca.ca_state = 'CA'
          AND i.i_current_price BETWEEN 10 AND 100
          AND p.p_discount_active = 'Y'
    ),
    high_qty AS (
        SELECT DISTINCT cs_order_number FROM base WHERE cs_quantity > 10
    ),
    profitable AS (
        SELECT DISTINCT cs_order_number FROM base WHERE cs_net_profit > 0
    ),
    returns AS (
        SELECT DISTINCT cs_order_number FROM base WHERE cr_return_quantity > 0
    ),
    intersect_orders AS (
        SELECT cs_order_number FROM high_qty
        INTERSECT
        SELECT cs_order_number FROM profitable
    ),
    final_orders AS (
        SELECT cs_order_number FROM intersect_orders
        EXCEPT
        SELECT cs_order_number FROM returns
    ),
    enriched AS (
        SELECT
            b.*, 
            ROW_NUMBER() OVER (PARTITION BY b.ca_state ORDER BY b.cs_net_paid DESC) AS rn,
            ws_agg.total_ws_qty
        FROM base b
        LEFT JOIN LATERAL (
            SELECT SUM(ws.ws_quantity) AS total_ws_qty
            FROM web_sales ws
            WHERE ws.ws_item_sk = b.cs_item_sk
        ) ws_agg ON TRUE
        WHERE b.cs_order_number IN (SELECT cs_order_number FROM final_orders)
    )
SELECT
    enriched.cc_call_center_id,
    enriched.cp_department,
    enriched.sm_type,
    enriched.w_warehouse_name,
    enriched.i_category,
    enriched.i_brand,
    COUNT(DISTINCT enriched.cs_order_number) AS orders_cnt,
    SUM(enriched.cs_quantity) AS total_quantity,
    SUM(enriched.cs_net_paid) AS total_net_paid,
    AVG(enriched.cs_net_profit) AS avg_net_profit,
    MIN(enriched.cs_net_paid) AS min_net_paid,
    MAX(enriched.cs_net_paid) AS max_net_paid,
    MAX(enriched.rn) AS max_row_number
FROM enriched
GROUP BY
    enriched.cc_call_center_id,
    enriched.cp_department,
    enriched.sm_type,
    enriched.w_warehouse_name,
    enriched.i_category,
    enriched.i_brand
ORDER BY total_net_paid DESC
LIMIT 100
