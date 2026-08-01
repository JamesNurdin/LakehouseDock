WITH catalog_data AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        cs.cs_order_number AS order_number,
        d.d_date AS sale_date,
        cc.cc_name AS call_center_name,
        w.w_warehouse_name AS warehouse_name,
        sm.sm_type AS ship_mode_type,
        p.p_promo_name AS promo_name,
        rs.r_reason_desc AS return_reason,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS item_sales_rank
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason rs ON cr.cr_reason_sk = rs.r_reason_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = cs.cs_sold_date_sk AND inv.inv_warehouse_sk = cs.cs_warehouse_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY cs.cs_item_sk, cs.cs_order_number, d.d_date, cc.cc_name, w.w_warehouse_name, sm.sm_type, p.p_promo_name, rs.r_reason_desc
),
web_data AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        ws.ws_order_number AS order_number,
        d2.d_date AS sale_date,
        NULL AS call_center_name,
        w2.w_warehouse_name AS warehouse_name,
        sm2.sm_type AS ship_mode_type,
        p2.p_promo_name AS promo_name,
        NULL AS return_reason,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS item_sales_rank
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    LEFT JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    LEFT JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    LEFT JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN inventory inv2 ON inv2.inv_date_sk = ws.ws_sold_date_sk AND inv2.inv_warehouse_sk = ws.ws_warehouse_sk
    WHERE d2.d_year = 2001
      AND p2.p_discount_active = 'Y'
      AND sm2.sm_type = 'AIR'
      AND t2.t_hour BETWEEN 9 AND 17
    GROUP BY ws.ws_item_sk, ws.ws_order_number, d2.d_date, w2.w_warehouse_name, sm2.sm_type, p2.p_promo_name
),
combined AS (
    SELECT
        item_sk,
        order_number,
        sale_date,
        call_center_name,
        warehouse_name,
        ship_mode_type,
        promo_name,
        return_reason,
        total_sales_amount,
        total_net_profit,
        sales_cnt,
        item_sales_rank,
        'catalog' AS source
    FROM catalog_data
    UNION ALL
    SELECT
        item_sk,
        order_number,
        sale_date,
        call_center_name,
        warehouse_name,
        ship_mode_type,
        promo_name,
        return_reason,
        total_sales_amount,
        total_net_profit,
        sales_cnt,
        item_sales_rank,
        'web' AS source
    FROM web_data
)
SELECT
    item_sk,
    order_number,
    sale_date,
    call_center_name,
    warehouse_name,
    ship_mode_type,
    promo_name,
    return_reason,
    total_sales_amount,
    total_net_profit,
    sales_cnt,
    item_sales_rank,
    source,
    DENSE_RANK() OVER (ORDER BY total_net_profit DESC) AS net_profit_rank
FROM combined
ORDER BY total_net_profit DESC, net_profit_rank
LIMIT 100
