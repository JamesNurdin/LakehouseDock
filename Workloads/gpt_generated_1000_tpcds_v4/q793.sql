WITH joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        ws.ws_net_profit,
        ss.ss_net_profit,
        cr.cr_net_loss,
        p.p_promo_id,
        p.p_promo_name,
        d.d_year,
        sm.sm_type,
        w.w_warehouse_name,
        w.w_warehouse_sk AS warehouse_sk,
        d.d_date_sk AS date_sk,
        cc.cc_name,
        ca.ca_state,
        t.t_hour,
        CASE
            WHEN (cs.cs_net_profit + COALESCE(ws.ws_net_profit, 0) + COALESCE(ss.ss_net_profit, 0) - COALESCE(cr.cr_net_loss, 0)) > 0 THEN 'POS'
            ELSE 'NEG'
        END AS overall_profit_flag,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN inventory inv
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
     AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_sold_time_sk = t.t_time_sk
     AND ws.ws_bill_customer_sk = c.c_customer_sk
     AND ws.ws_bill_addr_sk = ca.ca_address_sk
     AND ws.ws_promo_sk = p.p_promo_sk
     AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
     AND ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_sales ss
      ON ss.ss_sold_date_sk = d.d_date_sk
     AND ss.ss_sold_time_sk = t.t_time_sk
     AND ss.ss_customer_sk = c.c_customer_sk
     AND ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site we
      ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND p.p_channel_press = 'N'
      AND t.t_hour BETWEEN 9 AND 17
      AND w.w_city = 'Seattle'
)
SELECT
    overall_profit_flag,
    COUNT(*) AS txn_cnt,
    SUM(cs_net_profit) AS sum_catalog_profit,
    SUM(ws_net_profit) AS sum_web_profit,
    SUM(ss_net_profit) AS sum_store_profit,
    AVG(COALESCE(inv_quantity_on_hand, 0)) AS avg_inventory,
    SUM(
        CASE WHEN EXISTS (
            SELECT 1 FROM inventory inv2
            WHERE inv2.inv_warehouse_sk = joined_data.warehouse_sk
              AND inv2.inv_date_sk = joined_data.date_sk
              AND inv2.inv_quantity_on_hand > 0
        ) THEN 1 ELSE 0 END
    ) AS warehouses_with_stock
FROM joined_data
GROUP BY overall_profit_flag
HAVING COUNT(*) > 5
ORDER BY sum_catalog_profit DESC
LIMIT 100
