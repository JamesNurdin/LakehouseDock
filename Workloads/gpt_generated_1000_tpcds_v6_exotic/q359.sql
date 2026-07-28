WITH
store_data AS (
    SELECT
        d_ss.d_year,
        ca_ss.ca_state,
        s.s_store_name,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_return_loss
    FROM store_sales ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_returned_date_sk = d_ss.d_date_sk
    WHERE d_ss.d_year = 2001
      AND ca_ss.ca_state = 'CA'
      AND s.s_store_name LIKE 'Store%'
    GROUP BY d_ss.d_year, ca_ss.ca_state, s.s_store_name
),
web_data AS (
    SELECT
        d_ws.d_year,
        ca_ws_bill.ca_state AS bill_state,
        wp.wp_type,
        w_ws.w_county,
        p_ws.p_discount_active,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_return_loss
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_returned_date_sk = d_ws.d_date_sk
    WHERE d_ws.d_year = 2001
      AND w_ws.w_county = 'Daviess County'
      AND p_ws.p_discount_active = 'Y'
    GROUP BY d_ws.d_year, ca_ws_bill.ca_state, wp.wp_type, w_ws.w_county, p_ws.p_discount_active
),
union_sales AS (
    SELECT d_year, 'store' AS channel, store_net_paid AS total_paid
    FROM store_data
    UNION ALL
    SELECT d_year, 'web' AS channel, web_net_paid AS total_paid
    FROM web_data
),
inventory_data AS (
    SELECT
        d_inv.d_year,
        w_inv.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    WHERE d_inv.d_year = 2001
    GROUP BY d_inv.d_year, w_inv.w_warehouse_name
),
catalog_data AS (
    SELECT
        d_cs.d_year,
        cc.cc_name,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d_cs.d_year = 2001
      AND cc.cc_name LIKE '%Center%'
    GROUP BY d_cs.d_year, cc.cc_name
)
SELECT
    u.d_year,
    u.channel,
    u.total_paid,
    sd.store_quantity,
    sd.store_return_loss,
    wd.web_quantity,
    wd.web_return_loss,
    id.total_on_hand,
    cd.catalog_net_paid,
    cd.avg_discount,
    (SELECT COUNT(*) FROM call_center WHERE cc_name LIKE '%Center%') AS total_call_centers
FROM union_sales u
LEFT JOIN store_data sd
    ON u.d_year = sd.d_year
    AND u.channel = 'store'
LEFT JOIN web_data wd
    ON u.d_year = wd.d_year
    AND u.channel = 'web'
LEFT JOIN inventory_data id
    ON u.d_year = id.d_year
LEFT JOIN catalog_data cd
    ON u.d_year = cd.d_year
ORDER BY u.d_year DESC, u.channel
LIMIT 100
