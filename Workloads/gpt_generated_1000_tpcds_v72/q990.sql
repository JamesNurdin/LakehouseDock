WITH inventory_agg AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk
),
sales_customer AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        c.c_customer_id,
        d.d_year,
        i.i_brand,
        i.i_item_id,
        p.p_promo_name,
        cc.cc_state,
        cc.cc_name,
        sm.sm_ship_mode_id,
        w.w_warehouse_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'BrandX'
      AND cc.cc_state = 'CA'
),
agg AS (
    SELECT
        sc.c_customer_id,
        sc.i_item_id,
        sc.i_brand,
        sc.cc_name,
        sc.p_promo_name,
        sc.w_warehouse_name,
        SUM(sc.cs_net_paid) AS total_catalog_net_paid,
        COUNT(DISTINCT sc.cs_order_number) AS distinct_orders,
        SUM(ss.ss_net_paid) AS total_store_net_paid,
        SUM(ws.ws_net_paid) AS total_web_net_paid,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        SUM(inv.total_quantity) AS total_inventory_qty
    FROM sales_customer sc
    LEFT JOIN store_sales ss
        ON ss.ss_item_sk = sc.cs_item_sk
    LEFT JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    LEFT JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = sc.cs_item_sk
    LEFT JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    LEFT JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site webs ON ws.ws_web_site_sk = webs.web_site_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = sc.cs_order_number
    LEFT JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    LEFT JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN inventory_agg inv
        ON inv.inv_item_sk = sc.cs_item_sk
       AND inv.inv_warehouse_sk = sc.cs_warehouse_sk
    WHERE ws.ws_quantity > 5
    GROUP BY
        sc.c_customer_id,
        sc.i_item_id,
        sc.i_brand,
        sc.cc_name,
        sc.p_promo_name,
        sc.w_warehouse_name
)
SELECT
    a.c_customer_id,
    a.i_item_id,
    a.i_brand,
    a.cc_name,
    a.p_promo_name,
    a.w_warehouse_name,
    a.total_catalog_net_paid,
    a.distinct_orders,
    a.total_store_net_paid,
    a.total_web_net_paid,
    a.total_catalog_return_loss,
    a.total_store_return_loss,
    a.total_web_return_loss,
    a.total_inventory_qty,
    ROW_NUMBER() OVER (PARTITION BY a.c_customer_id ORDER BY a.total_catalog_net_paid DESC) AS customer_rank
FROM agg a
ORDER BY a.total_catalog_net_paid DESC
LIMIT 100
