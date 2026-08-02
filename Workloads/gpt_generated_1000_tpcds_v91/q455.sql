WITH base_data AS (
    SELECT
        d.d_year,
        d.d_date,
        i.i_brand,
        sm.sm_type,
        ss.ss_net_paid,
        ws.ws_net_paid,
        cr.cr_net_loss,
        sr.sr_net_loss,
        wr.wr_net_loss,
        inv_agg.total_inventory_qty
    FROM store_sales ss
    INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    INNER JOIN item i ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    INNER JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    INNER JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
       AND cr.cr_returned_date_sk = d.d_date_sk
       AND cr.cr_returned_time_sk = t.t_time_sk
    INNER JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
       AND ws.ws_sold_date_sk = d.d_date_sk
       AND ws.ws_sold_time_sk = t.t_time_sk
    INNER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
       AND ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
       AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = i.i_item_sk
    CROSS JOIN LATERAL (
        SELECT SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
        FROM inventory inv
        WHERE inv.inv_item_sk = i.i_item_sk
          AND inv.inv_warehouse_sk = w.w_warehouse_sk
          AND inv.inv_date_sk = d.d_date_sk
    ) AS inv_agg
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND sm.sm_type = 'EXPRESS'
      AND wp.wp_max_ad_count >= 2
)
SELECT
    d_year,
    i_brand,
    sm_type,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(cr_net_loss) AS total_catalog_loss,
    SUM(sr_net_loss) AS total_store_return_loss,
    SUM(wr_net_loss) AS total_web_return_loss,
    SUM(total_inventory_qty) AS total_inventory_qty,
    CASE
        WHEN SUM(ss_net_paid) + SUM(ws_net_paid) - SUM(cr_net_loss) - SUM(sr_net_loss) - SUM(wr_net_loss) > 0
        THEN 'PROFIT'
        ELSE 'LOSS'
    END AS profit_flag
FROM base_data
GROUP BY GROUPING SETS (
    (d_year, i_brand, sm_type),
    (d_year, i_brand),
    (i_brand),
    ()
)
ORDER BY total_store_sales DESC
LIMIT 100
