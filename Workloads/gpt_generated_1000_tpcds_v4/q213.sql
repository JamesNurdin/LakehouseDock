WITH inv_summary AS (
        SELECT inv_item_sk,
               MAX(inv_quantity_on_hand) AS max_qty
        FROM inventory
        GROUP BY inv_item_sk
    ),
    joined AS (
        SELECT
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            i.i_item_sk,
            i.i_product_name,
            cs.cs_order_number,
            cs.cs_quantity,
            cs.cs_net_profit AS cs_net_profit,
            ws.ws_order_number,
            ws.ws_quantity AS ws_quantity,
            ws.ws_net_profit AS ws_net_profit,
            cr.cr_return_quantity,
            wr.wr_return_quantity,
            inv_summary.max_qty,
            cc.cc_name,
            sm.sm_type,
            w.w_warehouse_name,
            p.p_promo_name,
            td.t_meal_time
        FROM catalog_sales cs
        JOIN time_dim td
          ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN customer c
          ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca
          ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd
          ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN call_center cc
          ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm
          ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w
          ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN item i
          ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p
          ON cs.cs_promo_sk = p.p_promo_sk
        LEFT JOIN catalog_returns cr
          ON cr.cr_order_number = cs.cs_order_number
         AND cr.cr_item_sk = cs.cs_item_sk
        LEFT JOIN web_sales ws
          ON ws.ws_item_sk = cs.cs_item_sk
         AND ws.ws_sold_time_sk = td.t_time_sk
        LEFT JOIN web_returns wr
          ON wr.wr_order_number = ws.ws_order_number
         AND wr.wr_item_sk = ws.ws_item_sk
        LEFT JOIN web_page wp
          ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_site webs
          ON ws.ws_web_site_sk = webs.web_site_sk
        LEFT JOIN inv_summary
          ON inv_summary.inv_item_sk = i.i_item_sk
        WHERE td.t_meal_time = 'dinner'
          AND i.i_class_id IN (12, 14)
          AND cs.cs_quantity > 5
          AND cs.cs_net_profit > 0
          AND inv_summary.max_qty > 0
    )
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    i_item_sk,
    i_product_name,
    cs_order_number,
    cs_quantity,
    cs_net_profit,
    ws_order_number,
    ws_quantity,
    ws_net_profit,
    (cs_net_profit + ws_net_profit) AS total_profit,
    max_qty,
    cc_name,
    sm_type,
    w_warehouse_name,
    p_promo_name,
    t_meal_time,
    RANK() OVER (PARTITION BY c_customer_sk ORDER BY (cs_net_profit + ws_net_profit) DESC) AS profit_rank,
    CASE WHEN cr_return_quantity IS NOT NULL THEN 'Catalog Return' ELSE 'No Catalog Return' END AS catalog_return_flag,
    CASE WHEN wr_return_quantity IS NOT NULL THEN 'Web Return' ELSE 'No Web Return' END AS web_return_flag
FROM joined
ORDER BY total_profit DESC
LIMIT 100
