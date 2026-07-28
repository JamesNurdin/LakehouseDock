WITH avg_store_profit AS (
    SELECT AVG(ss.ss_net_profit) AS avg_profit
    FROM store_sales ss
),
sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        s.s_state,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit)) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM
        store_sales ss
        JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
        JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
        JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
        -- Catalog Sales and related dimensions
        JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
        JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
        JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
        JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
        -- Catalog Returns and related dimensions
        JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
        JOIN call_center cc_cr ON cr.cr_call_center_sk = cc_cr.cc_call_center_sk
        JOIN catalog_page cp_cr ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
        JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
        JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
        -- Web Sales and related dimensions
        JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
        JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
        JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
        -- Web Returns and related dimensions
        JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
        JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
        JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
    WHERE
        t_ss.t_hour BETWEEN 9 AND 17                     -- business hours
        AND i.i_current_price > 100                      -- mid‑range items only
        AND s.s_state = 'TX'                             -- Texas stores
        AND p.p_discount_active = 'Y'                    -- active promotions
        AND cr.cr_return_quantity > 10                   -- substantial catalog returns
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        s.s_state
    HAVING
        SUM(ss.ss_net_profit) > 10000                    -- only high‑profit items
)
SELECT
    a.i_item_id,
    a.i_product_name,
    a.s_state,
    a.store_net_profit,
    a.catalog_net_profit,
    a.web_net_profit,
    a.total_net_profit,
    CASE WHEN a.store_net_profit > (SELECT avg_profit FROM avg_store_profit) THEN 1 ELSE 0 END AS above_avg_store_profit,
    RANK() OVER (ORDER BY a.total_net_profit DESC) AS total_profit_rank
FROM sales_agg a
ORDER BY total_profit_rank
LIMIT 100
