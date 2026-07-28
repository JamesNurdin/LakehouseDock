WITH joined_data AS (
    SELECT
        s.s_store_id,
        d.d_year,
        ss.ss_net_paid,
        cs.cs_net_paid,
        ws.ws_net_paid,
        sr.sr_net_loss,
        cr.cr_net_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk

    -- catalog side
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk

    -- returns side
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                         AND cr.cr_item_sk = i.i_item_sk
                         AND cr.cr_order_number = cs.cs_order_number
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                         AND sr.sr_item_sk = i.i_item_sk
                         AND sr.sr_ticket_number = ss.ss_ticket_number

    -- web side
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                     AND ws.ws_item_sk = i.i_item_sk
                     AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                     AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk

    -- inventory side
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                      AND inv.inv_item_sk = i.i_item_sk
                      AND inv.inv_warehouse_sk = w.w_warehouse_sk

    WHERE d.d_year = 2001
      AND i.i_units = 'Each'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cp.cp_department = 'DEPARTMENT'
      AND w.w_gmt_offset > 0
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_order_number = cs.cs_order_number
            AND cr2.cr_return_quantity > 0
      )
),
store_year_agg AS (
    SELECT
        s_store_id,
        d_year,
        SUM(ss_net_paid) AS sum_store_sales,
        SUM(cs_net_paid) AS sum_catalog_sales,
        SUM(ws_net_paid) AS sum_web_sales,
        SUM(sr_net_loss) AS sum_store_returns,
        SUM(cr_net_loss) AS sum_catalog_returns
    FROM joined_data
    GROUP BY s_store_id, d_year
    HAVING SUM(ss_net_paid) > 10000
),
final_agg AS (
    SELECT
        s_store_id,
        d_year,
        (sum_store_sales + sum_catalog_sales + sum_web_sales - sum_store_returns - sum_catalog_returns) AS net_total
    FROM store_year_agg
)
SELECT
    s_store_id,
    d_year,
    net_total
FROM final_agg
WHERE net_total > (SELECT AVG(net_total) FROM final_agg)
ORDER BY net_total DESC
LIMIT 100
