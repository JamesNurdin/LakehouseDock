WITH inventory_agg AS (
    SELECT 
        inv_item_sk,
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk, inv_date_sk
)
SELECT
    ss.ss_ticket_number,
    ws.ws_order_number,
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    i.i_item_id,
    i.i_category,
    i.i_current_price,
    d_ss.d_year,
    d_ss.d_month_seq,
    t_ss.t_hour,
    ws.ws_net_paid,
    ss.ss_net_paid,
    inv_agg.total_quantity_on_hand,
    w.w_warehouse_name,
    sm.sm_ship_mode_id,
    sm.sm_code,
    cc.cc_name,
    wp.wp_url,
    RANK() OVER (
        PARTITION BY d_ss.d_year
        ORDER BY (COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0)) DESC
    ) AS profit_rank,
    (
        SELECT MAX(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = ws.ws_item_sk
          AND ws2.ws_sold_date_sk = ws.ws_sold_date_sk
    ) AS max_day_net_paid_for_item
FROM store_sales ss
JOIN date_dim d_ss
    ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN time_dim t_ss
    ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_ss.d_date_sk
   AND ws.ws_item_sk = i.i_item_sk
   AND ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   AND ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
   AND wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_wp_create
    ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN inventory_agg inv_agg
    ON inv_agg.inv_item_sk = i.i_item_sk
   AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
   AND inv_agg.inv_date_sk = d_ss.d_date_sk
JOIN call_center cc
    ON cc.cc_open_date_sk = d_ss.d_date_sk
WHERE
    d_ss.d_year = 2001
    AND i.i_current_price > 20
    AND ca.ca_state = 'CA'
    AND sm.sm_code = 'AIR'
    AND t_ss.t_hour BETWEEN 9 AND 17
    AND c.c_current_cdemo_sk = cd.cd_demo_sk
    AND c.c_current_addr_sk = ca.ca_address_sk
ORDER BY profit_rank
LIMIT 100
