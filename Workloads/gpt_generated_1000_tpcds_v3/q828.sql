WITH base_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_quantity,
        i.i_category,
        i.i_brand,
        i.i_product_name,
        p.p_promo_name,
        p.p_discount_active,
        cc.cc_name,
        cc.cc_state,
        s.s_store_name AS s_store_name,
        s.s_state AS s_state,
        sm.sm_type,
        w.w_warehouse_name,
        t.t_hour AS t_hour,
        cd_bill.cd_purchase_estimate,
        CASE WHEN cs.cs_net_profit > 0 THEN 1 ELSE 0 END AS profit_flag,
        ss.ss_quantity AS store_quantity,
        ws.ws_quantity AS web_quantity
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE cc.cc_country = 'United States'
      AND p.p_channel_tv = 'N'
      AND cd_bill.cd_purchase_estimate > 1000
)
SELECT
    s_store_name,
    p_promo_name,
    t_hour,
    SUM(cs_net_paid) AS total_net_paid,
    SUM(cs_net_profit) AS total_net_profit,
    SUM(cs_quantity) AS total_quantity,
    AVG(CASE WHEN profit_flag = 1 THEN cs_net_profit END) AS avg_positive_profit,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    CASE WHEN SUM(cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS overall_profit_flag
FROM base_sales
GROUP BY s_store_name, p_promo_name, t_hour
HAVING SUM(cs_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
