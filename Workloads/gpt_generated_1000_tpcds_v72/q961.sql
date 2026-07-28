WITH base AS (
    SELECT
        d.d_year,
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid AS ss_net_paid,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid AS cs_net_paid,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid AS ws_net_paid,
        p.p_promo_sk,
        p.p_discount_active,
        r.r_reason_sk,
        sm.sm_ship_mode_id,
        w.w_warehouse_sk,
        inv.inv_quantity_on_hand,
        cr.cr_return_quantity,
        sr.sr_return_quantity,
        wr.wr_return_quantity,
        t.t_hour
    FROM date_dim d
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_order_number = cs.cs_order_number
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2002
      AND s.s_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_promo_sk = p.p_promo_sk
            AND p2.p_discount_active = 'Y'
      )
)
SELECT
    d_year,
    s_store_name,
    i_category,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(ss_net_paid + cs_net_paid + ws_net_paid) AS total_combined_sales
FROM base
GROUP BY ROLLUP (d_year, s_store_name, i_category)
HAVING SUM(ss_net_paid + cs_net_paid + ws_net_paid) > 100000
ORDER BY total_combined_sales DESC
LIMIT 100
