WITH union_data AS (
    -- Catalog channel
    SELECT
        d.d_year,
        d.d_date,
        s.s_store_name,
        cs.cs_order_number AS order_number,
        cs.cs_net_profit AS net_profit,
        cr.cr_net_loss AS net_loss,
        inv.inv_quantity_on_hand AS inventory_qty,
        CASE WHEN cr.cr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
        wsagg.store_sales_total,
        (
            SELECT SUM(ws2.ws_ext_sales_price)
            FROM web_sales ws2
            WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk
              AND ws2.ws_sold_date_sk = d.d_date_sk
        ) AS total_ws_sales
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store s
        ON s.s_store_sk = ss.ss_store_sk
    CROSS JOIN LATERAL (
        SELECT SUM(ss2.ss_ext_sales_price) AS store_sales_total
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
          AND ss2.ss_sold_date_sk = d.d_date_sk
    ) AS wsagg
    WHERE d.d_year = 2002

    UNION

    -- Web channel
    SELECT
        d.d_year,
        d.d_date,
        s.s_store_name,
        ws.ws_order_number AS order_number,
        ws.ws_net_profit AS net_profit,
        wr.wr_net_loss AS net_loss,
        inv.inv_quantity_on_hand AS inventory_qty,
        CASE WHEN wr.wr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
        wsagg.store_sales_total,
        (
            SELECT SUM(ws2.ws_ext_sales_price)
            FROM web_sales ws2
            WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk
              AND ws2.ws_sold_date_sk = d.d_date_sk
        ) AS total_ws_sales
    FROM web_sales ws
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
        ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store s
        ON s.s_store_sk = ss.ss_store_sk
    CROSS JOIN LATERAL (
        SELECT SUM(ss2.ss_ext_sales_price) AS store_sales_total
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
          AND ss2.ss_sold_date_sk = d.d_date_sk
    ) AS wsagg
    WHERE d.d_year = 2002
),
aggregated AS (
    SELECT
        u.d_year,
        u.d_date,
        u.s_store_name,
        SUM(u.net_profit) AS total_net_profit,
        SUM(u.net_loss)   AS total_net_loss,
        SUM(u.inventory_qty) AS total_inventory_qty,
        SUM(u.total_ws_sales) AS total_ws_sales,
        MAX(u.loss_category) AS loss_category
    FROM union_data u
    GROUP BY u.d_year, u.d_date, u.s_store_name, u.loss_category
)
SELECT
    a.d_year,
    a.d_date,
    a.s_store_name,
    a.total_net_profit,
    a.total_net_loss,
    a.total_inventory_qty,
    a.total_ws_sales,
    a.loss_category,
    RANK() OVER (ORDER BY a.total_net_loss DESC) AS loss_rank,
    SUM(a.total_net_loss) OVER (PARTITION BY a.d_year ORDER BY a.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_year_loss
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 100
