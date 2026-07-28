WITH joined_data AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        ss.ss_net_profit AS ss_net_profit,
        ws.ws_net_profit AS ws_net_profit,
        sr.sr_net_loss AS sr_net_loss,
        cr.cr_net_loss AS cr_net_loss,
        inv.inv_quantity_on_hand AS inv_qty,
        td.t_am_pm,
        td.t_second,
        w.w_city,
        p.p_discount_active,
        cr.cr_return_tax,
        ss.ss_quantity
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss ON td.t_time_sk = ss.ss_sold_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE td.t_am_pm = 'PM'
      AND td.t_second BETWEEN 1 AND 14
      AND w.w_city = 'Seattle'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cr.cr_return_tax > 50
      AND ss.ss_quantity >= 2
      AND ws.ws_net_profit > 0
)
SELECT
    s_store_id,
    s_store_name,
    SUM(COALESCE(ss_net_profit, 0))
        + SUM(COALESCE(ws_net_profit, 0))
        - SUM(COALESCE(sr_net_loss, 0))
        - SUM(COALESCE(cr_net_loss, 0)) AS total_profit,
    RANK() OVER (
        ORDER BY 
            SUM(COALESCE(ss_net_profit, 0))
            + SUM(COALESCE(ws_net_profit, 0))
            - SUM(COALESCE(sr_net_loss, 0))
            - SUM(COALESCE(cr_net_loss, 0)) DESC
    ) AS profit_rank,
    CASE
        WHEN SUM(COALESCE(ss_net_profit, 0))
             + SUM(COALESCE(ws_net_profit, 0))
             - SUM(COALESCE(sr_net_loss, 0))
             - SUM(COALESCE(cr_net_loss, 0)) > 5000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS profit_category
FROM joined_data
GROUP BY s_store_id, s_store_name
HAVING SUM(COALESCE(ss_net_profit, 0))
       + SUM(COALESCE(ws_net_profit, 0))
       - SUM(COALESCE(sr_net_loss, 0))
       - SUM(COALESCE(cr_net_loss, 0)) > 1000
ORDER BY total_profit DESC
LIMIT 100
