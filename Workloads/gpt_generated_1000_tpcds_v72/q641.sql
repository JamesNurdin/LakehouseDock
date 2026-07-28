WITH base AS (
    SELECT
        cc.cc_call_center_id,
        d_cc_open.d_year AS cc_open_year,
        d_cc_close.d_year AS cc_close_year,
        sr.sr_ticket_number,
        d_cc_close.d_date AS return_date,
        td_ret.t_hour AS return_hour,
        i.i_item_id,
        i.i_product_name,
        c.c_customer_id,
        hd.hd_buy_potential,
        ca.ca_city,
        s.s_store_id,
        s.s_state,
        ws.ws_order_number,
        d_ws.d_year AS sales_year,
        td_ws.t_hour AS sales_hour,
        i_ws.i_item_id AS sales_item_id,
        ws.ws_net_paid,
        ws.ws_net_profit,
        wp.wp_web_page_id,
        ws_site.web_name,
        sm.sm_ship_mode_id,
        wh.w_warehouse_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        inv_latest.inv_quantity_on_hand
    FROM call_center cc
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_close
        ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
    -- Store Returns and related dimensions
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_cc_close.d_date_sk
    JOIN time_dim td_ret
        ON sr.sr_return_time_sk = td_ret.t_time_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    -- Web Sales and related dimensions
    JOIN date_dim d_ws
        ON d_ws.d_date_sk = (
            SELECT ws.ws_sold_date_sk
            FROM web_sales ws
            WHERE ws.ws_order_number = ws.ws_order_number -- placeholder to force correlation later
            LIMIT 1
        )
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim td_ws
        ON ws.ws_sold_time_sk = td_ws.t_time_sk
    JOIN item i_ws
        ON ws.ws_item_sk = i_ws.i_item_sk
    JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh
        ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    -- Income band linked through household demographics
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    -- Lateral join to fetch the latest inventory quantity for the sold item on the sale date
    CROSS JOIN LATERAL (
        SELECT inv.inv_quantity_on_hand
        FROM inventory inv
        WHERE inv.inv_item_sk = i_ws.i_item_sk
          AND inv.inv_date_sk = d_ws.d_date_sk
        ORDER BY inv.inv_date_sk DESC
        LIMIT 1
    ) AS inv_latest
)
SELECT
    s_state,
    web_name,
    sales_year,
    SUM(ws_net_paid) AS total_net_paid,
    SUM(ws_net_profit) AS total_net_profit,
    CASE WHEN SUM(ws_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    MAX(inv_quantity_on_hand) AS max_inventory_on_hand
FROM base
GROUP BY ROLLUP (s_state, web_name, sales_year)
ORDER BY total_net_profit DESC
LIMIT 100
